# Oracle Berkeley DB

This repository based on **Oracle Berkeley DB 11g Release 2**, library version 11.2.(5.3.28) - latest version of the open-source edition Berkeley DB which licensed under the Berkeley Database License (a.k.a. the Sleepycat Software Product License). Starting with next version 12.1.(6.0.20), the open-source editions are licensed under the [GNU AGPLv3](https://www.gnu.org/licenses/why-affero-gpl.html).

[C API Reference](https://positeral.github.io/libdb5/api_reference/C/frame_main.html)

[C++ API Reference](https://positeral.github.io/libdb5/api_reference/CXX/frame_main.html)

[Berkeley DB Transactional Data Store](https://positeral.github.io/libdb5/programmer_reference/transapp.html)

[ Architecting Transactional Data Store applications](https://positeral.github.io/libdb5/programmer_reference/transapp_app.html)

[What Berkeley DB is not](https://positeral.github.io/libdb5/programmer_reference/intro_dbisnot.html)

To view release and installation original documentation, load the distribution file docs/index.html into your web browser or [visit this site here](https://positeral.github.io/libdb5). To perform a typical UNIX build & installation of Berkeley DB, enter the following commands:
```sh
git clone https://github.com/Positeral/libdb5.git
cd libdb5/build_unix
../dist/configure prefix=/usr 
make
sudo make install
```
See [Building Berkeley DB for UNIX/POSIX](https://positeral.github.io/libdb5/installation/build_unix.html) for installation details.
