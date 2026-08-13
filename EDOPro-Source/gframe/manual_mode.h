#ifndef MANUAL_MODE_H
#define MANUAL_MODE_H

#include <cstdint>

namespace ygo {

class ClientField;

class ManualMode {
public:
	static bool StartLocal();
	static void Stop();
	static bool IsActive();
	static bool ShowContextMenu(ClientField& field, int x, int y);
	static bool HandleCommand(ClientField& field, int command_id);

private:
	static bool active;
};

}

#endif // MANUAL_MODE_H
