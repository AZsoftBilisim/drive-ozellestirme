#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns the codes of the measure of the quantity of the item of calculation of the CCT.
// 
// Returns:
//  Map
//
Function CodesOfMeasureOfQuantityOfSubjectOfCalculationOfCCT() Export
	
	QuantityMeasures = New Map();
	
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Piece"), 0);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Gram"), 10);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Kilogram"), 11);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Ton"), 12);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Centimeter"), 20);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Decimeter"), 21);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Metre"), 22);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.SquareCentimeter"), 30);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.SquareDecimeter"), 31);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.SquareMeter"), 32);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Milliliter"), 40);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Liter"), 41);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.CubicMeter"), 42);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.KilowattHour"), 50);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Gigacaloria"), 51);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.FullDay"), 70);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Hour"), 71);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Minute"), 72);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Second"), 73);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Kilobytes"), 80);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Megabyte"), 81);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Gigabyte"), 82);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Terabyte"), 83);
	QuantityMeasures.Insert(PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.OtherUnitsOfMeasurement"), 255);
	
	Return QuantityMeasures;
	
EndFunction

// Returns measures of the quantity of the calculation item by codes.
// 
// Returns:
//  Map
//
Function MeasureOfQuantityOfSubjectOfCalculationOfKKTByCode() Export
	
	QuantityMeasures = New Map();
	
	QuantityMeasures.Insert(0, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Piece"));
	QuantityMeasures.Insert(10, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Gram"));
	QuantityMeasures.Insert(11, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Kilogram"));
	QuantityMeasures.Insert(12, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Ton"));
	QuantityMeasures.Insert(20, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Centimeter"));
	QuantityMeasures.Insert(21, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Decimeter"));
	QuantityMeasures.Insert(22, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Metre"));
	QuantityMeasures.Insert(30, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.SquareCentimeter"));
	QuantityMeasures.Insert(31, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.SquareDecimeter"));
	QuantityMeasures.Insert(32, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.SquareMeter"));
	QuantityMeasures.Insert(40, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Milliliter"));
	QuantityMeasures.Insert(41, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Liter"));
	QuantityMeasures.Insert(42, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.CubicMeter"));
	QuantityMeasures.Insert(50, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.KilowattHour"));
	QuantityMeasures.Insert(51, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Gigacaloria"));
	QuantityMeasures.Insert(70, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.FullDay"));
	QuantityMeasures.Insert(71, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Hour"));
	QuantityMeasures.Insert(72, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Minute"));
	QuantityMeasures.Insert(73, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Second"));
	QuantityMeasures.Insert(80, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Kilobytes"));
	QuantityMeasures.Insert(81, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Megabyte"));
	QuantityMeasures.Insert(82, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Gigabyte"));
	QuantityMeasures.Insert(83, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Terabyte"));
	QuantityMeasures.Insert(255, PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.OtherUnitsOfMeasurement"));
	
	Return QuantityMeasures;
	
EndFunction

// Returns a measure of the quantity of the calculation item by the unit code.
// 
// Returns:
//  Map
// 
Function MeasureOfQuantityOfSubjectOfCalculationByUnitCode() Export
	
	QuantityMeasures = New Map();
	
	QuantityMeasures.Insert("796", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Piece"));
	
	QuantityMeasures.Insert("163", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Gram"));
	QuantityMeasures.Insert("166", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Kilogram"));
	QuantityMeasures.Insert("168", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Ton"));
	
	QuantityMeasures.Insert("004", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Centimeter"));
	QuantityMeasures.Insert("005", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Decimeter"));
	QuantityMeasures.Insert("006", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Metre"));
	
	QuantityMeasures.Insert("051", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.SquareCentimeter"));
	QuantityMeasures.Insert("053", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.SquareDecimeter"));
	QuantityMeasures.Insert("055", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.SquareMeter"));
	
	QuantityMeasures.Insert("111", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Milliliter"));
	QuantityMeasures.Insert("112", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Liter"));
	QuantityMeasures.Insert("113", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.CubicMeter"));
	
	QuantityMeasures.Insert("245", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.KilowattHour"));
	QuantityMeasures.Insert("233", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Gigacaloria"));
	
	QuantityMeasures.Insert("359", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.FullDay"));
	QuantityMeasures.Insert("356", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Hour"));
	QuantityMeasures.Insert("355", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Minute"));
	QuantityMeasures.Insert("354", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Second"));
	
	QuantityMeasures.Insert("256", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Kilobytes"));
	QuantityMeasures.Insert("257", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Megabyte"));
	QuantityMeasures.Insert("2553", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Gigabyte"));
	QuantityMeasures.Insert("2554", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.Terabyte"));
	
	QuantityMeasures.Insert("OtherUnitsOfMeasurement", PredefinedValue("Enum.QuantityMeasureOfCRCalculationSubject.OtherUnitsOfMeasurement"));
	Return QuantityMeasures;
	
EndFunction

// Returns the unit code for the CCT code.
// 
// Returns:
//  Map
//
Function CodesOfUnitsOfMeasurementByKKTCode() Export
	
	UnitCodes = New Map;
	UnitCodes.Insert(0, "796");
	UnitCodes.Insert(10, "163");
	UnitCodes.Insert(11, "166");
	UnitCodes.Insert(12, "168");
	UnitCodes.Insert(20, "004");
	UnitCodes.Insert(21, "005");
	UnitCodes.Insert(22, "006");
	UnitCodes.Insert(30, "051");
	UnitCodes.Insert(31, "053");
	UnitCodes.Insert(32, "055");
	UnitCodes.Insert(40, "111");
	UnitCodes.Insert(41, "112");
	UnitCodes.Insert(42, "113");
	UnitCodes.Insert(50, "245");
	UnitCodes.Insert(51, "233");
	UnitCodes.Insert(70, "359");
	UnitCodes.Insert(71, "356");
	UnitCodes.Insert(72, "355");
	UnitCodes.Insert(73, "354");
	UnitCodes.Insert(80, "256");
	UnitCodes.Insert(81, "257");
	UnitCodes.Insert(82, "2553");
	UnitCodes.Insert(83, "2554");
	Return UnitCodes;
	
EndFunction

#EndRegion

#EndIf