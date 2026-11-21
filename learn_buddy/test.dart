void main() {
  print(RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch('user+test@gmail.com'));
}
