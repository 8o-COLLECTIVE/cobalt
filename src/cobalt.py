#!/usr/bin/python3

import aes
import os
import pyperclip
import hashlib
import argparse

parser = argparse.ArgumentParser(description='cobalt')

parser.add_argument('--debug', action='store_true', help='use debug mode')

args = parser.parse_args()

def main():
    keyresponse = input("Are you generating a key? [Y or current session key] ")

    if keyresponse.lower() == "y":
        print("\nPLEASE REMEMBER TO ENCRYPT THIS KEY BEFORE SENDING.\n\n")
        key = os.urandom(16).hex()
        print(f"The AES key for this session is: {key}\n")
        try:
            pyperclip.copy(f"The AES key for this session is: {key}")
            print("Keystring copied to clipboard!\n")
        except:
            pass
    else:
        key = keyresponse

    aesobj = aes.AES(bytearray.fromhex(key))

    key_hash = hashlib.md5(bytearray.fromhex(key)).hexdigest()

    print("\nAll messages encrypted with this key will start with: " + key_hash)

    print("\nTo encrypt a message, do e: [message]\n\nTo decrypt, do d: [message]")
    while True:
        print("\nBegin or hit Ctrl+C to exit.\n")
        message = input(">>")

        if ''.join(message[:3]) == "e: ":

            #removes command prefix
            message = message[3:]

            iv = os.urandom(16)

            print(f"\nEncrypted message: {key_hash}{iv.hex()}{aesobj.encrypt_ctr(bytes(message, 'ascii'), iv).hex()}")
            try:
                pyperclip.copy(f"{key_hash}{iv.hex()}{aesobj.encrypt_ctr(bytes(message, 'ascii'), iv).hex()}")
                print("\nMessage copied to clipboard!")
            except:
                pass
        elif ''.join(message[:3]) == "d: ":

            #removes command prefix
            message = message[3:]

            old_message = message

            #finds and removes key hash
            msg_hash = message[:32]
            message = message[32:]

            if msg_hash == key_hash and len(message) > 32:

                #removes and stores iv
                iv = message[:32]
                message = message[32:]

                print(f"\nDecrypted message: {aesobj.decrypt_ctr(bytearray.fromhex(message), bytearray.fromhex(iv)).decode('ascii')}")
            else:
                yn = input("\nKey hashes do not match, attempt decrypt anyway? [Y or N] ")

                if yn.lower() == "y":
                    iv = old_message[:32]
                    old_message = old_message[32:]
                    print(f"\nDecrypted message: {aesobj.decrypt_ctr(bytearray.fromhex(old_message), bytearray.fromhex(iv)).decode('ascii')}")
        else:
            print("Command not recognized.")

if __name__ == '__main__':
    if args.debug:
        main()
    else:
        try:
            main()
        except:
            pass
