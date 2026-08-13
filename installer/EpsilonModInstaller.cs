using System;
using System.IO;
using System.IO.Compression;
using System.Reflection;

namespace EpsilonModInstaller {
	internal sealed class SegmentStream : Stream {
		private readonly Stream baseStream;
		private readonly long offset;
		private readonly long length;
		private long position;

		public SegmentStream(Stream baseStream, long offset, long length) {
			this.baseStream = baseStream;
			this.offset = offset;
			this.length = length;
		}

		public override bool CanRead { get { return true; } }
		public override bool CanSeek { get { return true; } }
		public override bool CanWrite { get { return false; } }
		public override long Length { get { return length; } }
		public override long Position {
			get { return position; }
			set { Seek(value, SeekOrigin.Begin); }
		}

		public override void Flush() {}

		public override int Read(byte[] buffer, int arrayOffset, int count) {
			if(position >= length)
				return 0;
			count = (int)Math.Min(count, length - position);
			baseStream.Position = offset + position;
			var read = baseStream.Read(buffer, arrayOffset, count);
			position += read;
			return read;
		}

		public override long Seek(long seekOffset, SeekOrigin origin) {
			long next;
			switch(origin) {
			case SeekOrigin.Begin:
				next = seekOffset;
				break;
			case SeekOrigin.Current:
				next = position + seekOffset;
				break;
			case SeekOrigin.End:
				next = length + seekOffset;
				break;
			default:
				throw new ArgumentOutOfRangeException("origin");
			}
			if(next < 0)
				throw new IOException("Invalid seek before package start.");
			position = next;
			return position;
		}

		public override void SetLength(long value) {
			throw new NotSupportedException();
		}

		public override void Write(byte[] buffer, int offset, int count) {
			throw new NotSupportedException();
		}
	}

	internal static class Program {
		private const string Magic = "YGOCCGEPSILON01!";
		private const string AppName = "Yu-Gi-Oh CCG Epsilon";

		private static int Main(string[] args) {
			try {
				var exePath = Assembly.GetExecutingAssembly().Location;
				long zipOffset;
				long zipLength;
				if(!ReadPackageInfo(exePath, out zipOffset, out zipLength)) {
					Console.WriteLine("Installer package not found inside this executable.");
					return 1;
				}

				var targetDir = GetInstallDirectory(args);
				Console.WriteLine(AppName + " installer");
				Console.WriteLine("Install folder: " + targetDir);
				Console.WriteLine();
				Console.Write("Press Enter to install, or close this window to cancel...");
				Console.ReadLine();

				Directory.CreateDirectory(targetDir);
				using(var file = File.OpenRead(exePath))
				using(var package = new SegmentStream(file, zipOffset, zipLength))
				using(var archive = new ZipArchive(package, ZipArchiveMode.Read)) {
					var total = archive.Entries.Count;
					var done = 0;
					foreach(var entry in archive.Entries) {
						done++;
						var destination = Path.GetFullPath(Path.Combine(targetDir, entry.FullName));
						if(!destination.StartsWith(Path.GetFullPath(targetDir), StringComparison.OrdinalIgnoreCase))
							throw new IOException("Invalid package path: " + entry.FullName);
						if(string.IsNullOrEmpty(entry.Name)) {
							Directory.CreateDirectory(destination);
						} else {
							var parent = Path.GetDirectoryName(destination);
							if(!string.IsNullOrEmpty(parent))
								Directory.CreateDirectory(parent);
							entry.ExtractToFile(destination, true);
						}
						if(done % 100 == 0 || done == total)
							Console.WriteLine("Extracted " + done + " / " + total);
					}
				}

				CreateShortcut(targetDir);
				Console.WriteLine();
				Console.WriteLine("Done. Launch: " + Path.Combine(targetDir, "EDOProMod.exe"));
				Console.Write("Press Enter to close...");
				Console.ReadLine();
				return 0;
			}
			catch(Exception ex) {
				Console.WriteLine();
				Console.WriteLine("Install failed:");
				Console.WriteLine(ex);
				Console.Write("Press Enter to close...");
				Console.ReadLine();
				return 1;
			}
		}

		private static bool ReadPackageInfo(string exePath, out long zipOffset, out long zipLength) {
			zipOffset = 0;
			zipLength = 0;
			var magicBytes = System.Text.Encoding.ASCII.GetBytes(Magic);
			using(var file = File.OpenRead(exePath)) {
				var footerSize = magicBytes.Length + sizeof(long) * 2;
				if(file.Length < footerSize)
					return false;
				file.Position = file.Length - footerSize;
				var footer = new byte[footerSize];
				var read = file.Read(footer, 0, footer.Length);
				if(read != footer.Length)
					return false;
				zipOffset = BitConverter.ToInt64(footer, 0);
				zipLength = BitConverter.ToInt64(footer, sizeof(long));
				for(var i = 0; i < magicBytes.Length; ++i) {
					if(footer[sizeof(long) * 2 + i] != magicBytes[i])
						return false;
				}
				return zipOffset > 0 && zipLength > 0 && zipOffset + zipLength <= file.Length;
			}
		}

		private static string GetInstallDirectory(string[] args) {
			foreach(var arg in args) {
				if(arg.StartsWith("/DIR=", StringComparison.OrdinalIgnoreCase))
					return arg.Substring(5).Trim('"');
			}
			var defaultDir = Path.Combine(
				Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
				"Programs",
				AppName
			);
			Console.WriteLine("Default folder:");
			Console.WriteLine(defaultDir);
			Console.Write("Install folder, or Enter for default: ");
			var input = Console.ReadLine();
			return string.IsNullOrWhiteSpace(input) ? defaultDir : input.Trim('"');
		}

		private static void CreateShortcut(string targetDir) {
			try {
				var exe = Path.Combine(targetDir, "EDOProMod.exe");
				if(!File.Exists(exe))
					return;
				var desktop = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
				var shortcutPath = Path.Combine(desktop, AppName + ".lnk");
				var shellType = Type.GetTypeFromProgID("WScript.Shell");
				if(shellType == null)
					return;
				dynamic shell = Activator.CreateInstance(shellType);
				dynamic shortcut = shell.CreateShortcut(shortcutPath);
				shortcut.TargetPath = exe;
				shortcut.WorkingDirectory = targetDir;
				shortcut.Description = AppName;
				shortcut.Save();
			}
			catch {
			}
		}
	}
}
