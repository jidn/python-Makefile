alias make="make -f ../../Makefile"
ENV=.env
function msg() {
  tput setaf 3
  echo $1
  tput sgr0;
}
function err() {
  tput setaf 1
  echo -n "[$?] "
  echo $1
  tput sgr0
  exit 1
}
