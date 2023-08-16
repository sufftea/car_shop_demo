class CarData {
  const CarData({
    required this.yearStart,
    required this.yearEnd,
    required this.name,
    required this.picturePath,
  });

  final int yearStart;
  final int yearEnd;
  final String name;
  final String picturePath;

  static CarData fromYear(int year) {
    return _cars[year % _cars.length];
  }
}



const _cars = [
  CarData(
    yearStart: 1961,
    yearEnd: 1970,
    name: "Chevrolet Corvette C3",
    picturePath: 'assets/hotwheels.png',
  ),
  CarData(
    yearStart: 1962,
    yearEnd: 1963,
    name: "Chevrolet Corvette C1",
    picturePath: 'assets/hotwheels.png',
  ),
];


