#!/usr/bin/python3

import os
import pyperclip
import hashlib
import argparse

from .aes import AES
from .scraper import scrape
from .autoupdate import Updater


parser = argparse.ArgumentParser(description='cobalt')

parser.add_argument('--debug', action='store_true', help='use debug mode')
parser.add_argument('--scraper', action='store_true', help='use scraping mode')

args = parser.parse_args()


class Cobalt8:
    def __init__(self):
        exitcode = self.update() # TODO: something with this
        
        self.key = self.get_key()
        
        self.aes_obj = AES(self.key)
        
        self.key_hash = hashlib.md5(self.key).hexdigest()
        
        print("\nAll messages encrypted with this key will start with: " + self.key_hash)

        print("\nTo encrypt a message, do e: [message]\n\nTo decrypt, do d: [message]")
    
    
    def update(self):
        updater = Updater()
        if updater.needs_update():
            return updater.update()
    
    
    def __call__(self):
        if args.scraper:
            scrape()
        elif args.debug:
            self.get_command()
        else:
            try:
                self.get_command()
            except:
                pass
    
    
    def get_key(self):
        keyresponse = input("Are you generating a key? [Y or current session key] ")

        if keyresponse.lower() == "y":
            print("\nPLEASE REMEMBER TO ENCRYPT THIS KEY BEFORE SENDING.\n\n")
            key = os.urandom(16).hex()
            print("The AES key for this session is: {}\n".format(key))
            try:
                pyperclip.copy("The AES key for this session is: {}".format(key))
                print("Keystring copied to clipboard!\n")
            except:
                pass
        else:
            key = keyresponse
        
        return bytearray.fromhex(key)
        
        
    def encrypt(self, message):
        iv = os.urandom(16)
                    
        response = "{}{}{}".format(self.key_hash, iv.hex(), self.aes_obj.encrypt_ctr(bytes(message, 'ascii'), iv).hex())

        print("\nEncrypted message: {}".format(response))
        try:
            pyperclip.copy(response)
            print("\nMessage copied to clipboard!")
        except:
            pass
        
        return response
            
            
    def decrypt(self, message):
        decrypt_string = lambda string, iv: self.aes_obj.decrypt_ctr(bytearray.fromhex(string), bytearray.fromhex(iv)).decode('ascii')
        old_message = message

        #finds and removes key hash
        msg_hash = message[:32]
        message = message[32:]

        if msg_hash == self.key_hash and len(message) > 32:

            #removes and stores iv
            iv = message[:32]
            message = message[32:]

            response = decrypt_string(message, iv)
        else:
            yn = input("\nKey hashes do not match, attempt decrypt anyway? [Y or N] ")

            if yn.lower() == "y":
                iv = old_message[:32]
                old_message = old_message[32:]
                response = decrypt_string(old_message, iv)
                
        return response
        
                
    def get_command(self):
        while True:
            print("\nBegin or hit Ctrl+C to exit.\n")
            message = input(">>")
            if ''.join(message[:3]) == "e: ":
                response = self.encrypt(message[3:])
            elif ''.join(message[:3]) == "d: ":
                response = self.decrypt(message[3:])
                print("\nDecrypted message: " + response)
            else:
                print("Command not recognized.")


def entry():
    cobalt8 = Cobalt8()
    cobalt8()


if __name__ == '__main__':
    entry()
