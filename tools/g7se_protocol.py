"""Unverified G7 SE discovery candidates, used only by the hardware probe."""

from vendors.gamesir.models.g7se import protocol as se


def nexus_initialize(sequence):
    """Captured transient GIP startup candidate; Linux behavior not yet verified."""
    if not 1 <= sequence <= 255:
        raise ValueError('Startup sequence must be nonzero and fit in a byte')
    return bytes((5, 0x20, sequence, 1, 5))


def nexus_silent_rumble(sequence):
    """Captured companion startup packet; all four motor amplitudes are zero."""
    if not 1 <= sequence <= 255:
        raise ValueError('Startup sequence must be nonzero and fit in a byte')
    return bytes((9, 0, sequence, 9, 0, 15, 0, 0, 0, 0, 255, 0, 235))


def packet(sequence, command, payload):
    """Padded discovery candidate; production uses verified short requests."""
    return se.nexus_request(sequence, command, payload).ljust(64, b'\0')


def read_request(sequence, profile, offset, length):
    return packet(sequence, 5, bytes((4, profile)) + offset.to_bytes(2, 'big')
                  + bytes((length,)))


def fixed_length_read_request(sequence, profile, offset, length):
    """Unverified SE framing candidate using advertised 60-byte vendor size.

    Preserve the existing read-only inner command 04 and read tuple. Only the
    GIP payload length changes from 5 to 60; no register-write inner 03 allowed.
    """
    request = bytearray(read_request(sequence, profile, offset, length))
    request[3] = 60
    return bytes(request)


def legacy_packet(command, payload=b''):
    """Existing GameSir family framing; diagnostic candidates only on G7 SE."""
    payload = bytes(payload)
    allowed = command == 0xf2 and not payload
    if command == 4:
        allowed = (len(payload) == 4 and 1 <= payload[0] <= 4
                   and 1 <= payload[3] <= 55
                   and int.from_bytes(payload[1:3], 'big') + payload[3] <= 480)
    if not allowed:
        raise ValueError('Not an allowed legacy GameSir discovery request')
    return bytes((0x0f, command)) + payload + bytes(62 - len(payload))


def match_legacy_read(reply, profile, offset, length):
    reply = bytes(reply)
    echo = bytes((0x10, 5, profile)) + offset.to_bytes(2, 'big') + bytes((length,))
    if (1 <= profile <= 4 and 1 <= length <= 55 and 0 <= offset <= 480 - length
            and 6 + length <= len(reply) <= 64 and reply[:6] == echo):
        return reply[6:6 + length]
    return None
