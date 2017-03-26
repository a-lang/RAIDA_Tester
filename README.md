RAIDA Tester
============

The program is used to test CloudCoin RAIDA network, which is written in Bash.

It's able to work on all Linux distro and Mac OS. 

Demonstration: https://asciinema.org/a/5fhs1e9volg8zkaf0l27ru4py

![image](https://raw.githubusercontent.com/a-lang/RAIDA_Tester/master/raida-tester_on_Mac.png)


Requirement
-------------
* Curl
* Jq

How to use it?
---------------
1. You must have an authentic CloudCoin .stack file called 'testcoin.stack' in the same folder as this program to run tests.

2. Install the packages if they aren't installed yet.

```
sudo apt-get install curl
```

To install Jq on your computer please visit https://stedolan.github.io/jq/


3. Clone it to the computer then run it

```
git clone https://github.com/a-lang/RAIDA_Tester.git

cd RAIDA_Tester/

chmod +x *.sh

./raida_tester.sh
``` 

Hoping you like this.
