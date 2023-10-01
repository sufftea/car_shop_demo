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
    yearEnd: 1971,
    name: "Chevrolet Corvette C1",
    picturePath: 'assets/hotwheels.png',
  ),
  CarData(
    yearStart: 1962,
    yearEnd: 1972,
    name: "Chevrolet Corvette C2",
    picturePath: 'assets/hotwheels.png',
  ),
  CarData(
    yearStart: 1963,
    yearEnd: 1973,
    name: "Chevrolet Corvette C3",
    picturePath: 'assets/hotwheels.png',
  ),
  CarData(
    yearStart: 1964,
    yearEnd: 1974,
    name: "Chevrolet Corvette C4",
    picturePath: 'assets/hotwheels.png',
  ),
  CarData(
    yearStart: 1965,
    yearEnd: 1975,
    name: "Chevrolet Corvette C5",
    picturePath: 'assets/hotwheels.png',
  ),
];


