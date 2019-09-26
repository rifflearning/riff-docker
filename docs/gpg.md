# Working with GPG keys #

## Create a GPG key ##

&lt; this section has not been written yet! >

## Find and import a GPG key ##

To search for a key on the ubuntu keyserver:

```sh
gpg --keyserver keyserver.ubuntu.com --search-keys 'jordan reedie'
gpg --keyserver keyserver.ubuntu.com --search-keys 'jordan@rifflearning.com'
```

To display a key fingerprint:

```sh
gpg2 --fingerprint jordan@rifflearning.com
```

## Sign and export a GPG key ##

### sign ###
To sign a key once you've **verified** it (via matching the fingerprint obtained via a secure
channel preferably interactive, or in person):

```console
$ gpg2 --sign-key --ask-cert-level jordan@rifflearning.com

pub  rsa4096/85F55F59
     created: 2019-09-24  expires: 2020-09-23  usage: SC
     trust: unknown       validity: unknown
sub  rsa4096/19AE50F7
     created: 2019-09-24  expires: 2020-09-23  usage: E
[ unknown] (1). Jordan Reedie <jordan@rifflearning.com>


pub  rsa4096/85F55F59
     created: 2019-09-24  expires: 2020-09-23  usage: SC
     trust: unknown       validity: unknown
 Primary key fingerprint: 04DF 7FE9 6E21 AA2F C034  01BB D0D0 0361 85F5 5F59

     Jordan Reedie <jordan@rifflearning.com>

This key is due to expire on 2020-09-23.
How carefully have you verified the key you are about to sign actually belongs
to the person named above?  If you don't know what to answer, enter "0".

   (0) I will not answer. (default)
   (1) I have not checked at all.
   (2) I have done casual checking.
   (3) I have done very careful checking.

Your selection? (enter '?' for more information): 3
Are you sure that you want to sign this key with your
key "Michael Jay Lippert <mike@rifflearning.com>" (6A9A3282)

I have checked this key very carefully.

Really sign? (y/N) y
```

### export the signed key ###
```
$ gpg2 --keyserver keyserver.ubuntu.com --send-keys 85F55F59
```

Note the last command above to send the signed key back to the keyserver (uses the key ID)

### import the signed key ###
Then the owner of the key should be able to import the newly signed key using:
```
gpg --keyserver keyserver.ubuntu.com --recv-keys 85F55F59
```

Note I'm finding that frequently `gpg` is getting data from the keyserver more successfully than
`gpg2`?! _(from trying it on 2019-09-26)_

## Resources

- [The GNU Privacy Handbook: Key Management][gpg_keymgmt]
- [GPG Tutorial][]
- [Redhat Appendix B. Getting Started with Gnu Privacy Guard][redhat-gpg-doc]
- [PGP Key Signing][pgp-key-signing]
- [Check encrypted file recipients][check-file-recipients]
  `gpg2 --batch --list-packets somefile.gpg | grep '^gpg:'`
- [gpg2 man page][gpg2-man]

### Keyservers
- [Ubuntu PGP Key Server][] - Has been a good one to use so far.
- [OpenPGPkeyserver][]
- [MIT PGP Public Key Server][]


[gpg_keymgmt]: <https://www.gnupg.org/gph/en/manual/c235.html>
[GPG Tutorial]: <https://futureboy.us/pgp.html>
[redhat-gpg-doc]: <https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/4/html/Step_by_Step_Guide/ch-gnupg.html>
[pgp-key-signing]: <https://www.phildev.net/pgp/gpgsigning.html>
[check-file-recipients]: <https://security.stackexchange.com/questions/85157/can-i-check-who-can-decrypt-my-gpg-message-after-i-encrypt-it>
[gpg2-man]: <https://www.linux.org/docs/man1/gpg2.html>

[OpenPGPkeyserver]: <http://keys.gnupg.net/>
[MIT PGP Public Key Server]: <https://pgp.mit.edu/>
[Ubuntu PGP Key Server]: <https://keyserver.ubuntu.com/>