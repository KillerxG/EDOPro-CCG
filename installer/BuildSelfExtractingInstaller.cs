using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;

namespace EpsilonModInstallerBuild {
	internal sealed class OverlayWriteStream : Stream {
		private readonly Stream baseStream;
		private readonly long offset;
		private long length;
		private long position;

		public OverlayWriteStream(Stream baseStream, long offset) {
			this.baseStream = baseStream;
			this.offset = offset;
		}

		public override bool CanRead { get { return false; } }
		public override bool CanSeek { get { return true; } }
		public override bool CanWrite { get { return true; } }
		public override long Length { get { return length; } }
		public override long Position {
			get { return position; }
			set { Seek(value, SeekOrigin.Begin); }
		}

		public override void Flush() {
			baseStream.Flush();
		}

		public override int Read(byte[] buffer, int offset, int count) {
			throw new NotSupportedException();
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
			length = value;
			baseStream.SetLength(offset + value);
			if(position > value)
				position = value;
		}

		public override void Write(byte[] buffer, int arrayOffset, int count) {
			baseStream.Position = offset + position;
			baseStream.Write(buffer, arrayOffset, count);
			position += count;
			if(position > length)
				length = position;
		}
	}

	internal static class Program {
		private const string Magic = "YGOCCGEPSILON01!";

		private static readonly HashSet<string> ExcludedAnyDepthDirectories = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
			".git",
		};

		private static readonly HashSet<string> ExcludedRootDirectories = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
			"deck",
			"pics",
			"replay",
			"screenshots"
		};

		private static readonly HashSet<string> ExcludedFiles = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
			"error.log",
			"hd_cards_downloader_tracker",
			"hd_fields_downloader_tracker"
		};

		private static int Main(string[] args) {
			if(args.Length != 3) {
				Console.WriteLine("Usage: BuildSelfExtractingInstaller <sourceDir> <stubExe> <outputExe>");
				return 1;
			}

			var sourceDir = Path.GetFullPath(args[0]);
			var stubExe = Path.GetFullPath(args[1]);
			var outputExe = Path.GetFullPath(args[2]);
			Directory.CreateDirectory(Path.GetDirectoryName(outputExe));

			File.Copy(stubExe, outputExe, true);
			var zipOffset = new FileInfo(outputExe).Length;
			var fileCount = 0;

			using(var output = new FileStream(outputExe, FileMode.Open, FileAccess.ReadWrite, FileShare.None))
			using(var overlay = new OverlayWriteStream(output, zipOffset))
			using(var archive = new ZipArchive(overlay, ZipArchiveMode.Create, true)) {
				foreach(var file in EnumerateFiles(sourceDir)) {
					var relative = MakeRelative(sourceDir, file).Replace('\\', '/');
					var entry = archive.CreateEntry(relative, CompressionLevel.Fastest);
					using(var entryStream = entry.Open())
					using(var input = File.OpenRead(file)) {
						input.CopyTo(entryStream);
					}
					fileCount++;
					if(fileCount % 250 == 0)
						Console.WriteLine("Packed " + fileCount + " files");
				}
			}

			var zipLength = new FileInfo(outputExe).Length - zipOffset;
			using(var output = new FileStream(outputExe, FileMode.Append, FileAccess.Write, FileShare.None))
			using(var writer = new BinaryWriter(output)) {
				writer.Write(zipOffset);
				writer.Write(zipLength);
				writer.Write(System.Text.Encoding.ASCII.GetBytes(Magic));
			}

			Console.WriteLine("Packed " + fileCount + " files");
			Console.WriteLine("Output: " + outputExe);
			Console.WriteLine("Size: " + Math.Round(new FileInfo(outputExe).Length / 1024.0 / 1024.0 / 1024.0, 2) + " GB");
			return 0;
		}

		private static IEnumerable<string> EnumerateFiles(string sourceDir) {
			var stack = new Stack<string>();
			stack.Push(sourceDir);
			while(stack.Count > 0) {
				var dir = stack.Pop();
				foreach(var subdir in Directory.GetDirectories(dir)) {
					var rel = MakeRelative(sourceDir, subdir);
					if(!IsExcludedPath(rel))
						stack.Push(subdir);
				}
				foreach(var file in Directory.GetFiles(dir)) {
					var rel = MakeRelative(sourceDir, file);
					if(!IsExcludedPath(rel) && !ExcludedFiles.Contains(Path.GetFileName(file)))
						yield return file;
				}
			}
		}

		private static bool IsExcludedPath(string relativePath) {
			var parts = relativePath.Split(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
			if(parts.Length > 0 && ExcludedRootDirectories.Contains(parts[0]))
				return true;
			foreach(var part in parts) {
				if(ExcludedAnyDepthDirectories.Contains(part))
					return true;
			}
			return false;
		}

		private static string MakeRelative(string basePath, string path) {
			var baseUri = new Uri(AppendSeparator(basePath));
			var pathUri = new Uri(path);
			return Uri.UnescapeDataString(baseUri.MakeRelativeUri(pathUri).ToString()).Replace('/', Path.DirectorySeparatorChar);
		}

		private static string AppendSeparator(string path) {
			if(path.EndsWith(Path.DirectorySeparatorChar.ToString()) || path.EndsWith(Path.AltDirectorySeparatorChar.ToString()))
				return path;
			return path + Path.DirectorySeparatorChar;
		}
	}
}
