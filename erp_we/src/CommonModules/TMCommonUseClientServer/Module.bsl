#Region Public

#Region GeneralPurposeProceduresAndFunctions

// Calculates the end date of the period
//
// Parameters:
// StartDate - Date - the start date from which the end date of the period will be calculated
// Periodicity - Date - value of the "Frequency" enumeration"
// NumberOfPeriods - Number - the number of repetitions of the period.
//
// Returns:
// 	Date -
//
Function CalculatePeriodEndDate(StartDate, Periodicity, NumberOfPeriods) Export

	OneDay = 86400;

	If Periodicity = PredefinedValue("Enum.Periodicity.Day") Then 
		
		EndDate = StartDate + OneDay * NumberOfPeriods;

	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		
		EndDate = StartDate + OneDay * 7 * NumberOfPeriods;

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.TenDays")) Then
		
		MonthDay = Day(StartDate);
		BeginningOfMonth = BegOfMonth(StartDate);
		If MonthDay <= 10 Then
			DecadeNumber = 1;
		ElsIf MonthDay <= 20 Then
			DecadeNumber = 2;
		Else
			DecadeNumber = 3;
		EndIf;
			
		DecadeNumber = DecadeNumber + NumberOfPeriods;
		
		If DecadeNumber > 0 Then
			OfMonths = Int((DecadeNumber-1)/3);
		Else
			OfMonths = -1 - Int((-DecadeNumber)/3);
		EndIf;
			
		DecadeNumber = DecadeNumber - 3*OfMonths;
		Dr = AddMonth(BeginningOfMonth, OfMonths) + (DecadeNumber-1) * 10 * OneDay;

		If NumberOfPeriods > 0 Then
			EndDate = Dr;
		
		Else 
			MonthDay = Day(Dr);

			If MonthDay <= 10 Then
				EndDate = EndOfDay(BegOfMonth(Dr) + OneDay * 9);
			ElsIf MonthDay <= 20 Then
				EndDate = EndOfDay(BegOfMonth(Dr) + OneDay * 19);
			Else
				EndDate = EndOfMonth(Dr);
			EndIf;
		EndIf;

	ElsIf (Periodicity= PredefinedValue("Enum.Periodicity.Month")) Then
		
		EndDate = AddMonth(StartDate, NumberOfPeriods);

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Quarter")) Then
		
		EndDate = AddMonth(StartDate, 3 * NumberOfPeriods);

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.HalfYear")) Then
		
		EndDate = AddMonth(StartDate, 6 * NumberOfPeriods);

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Year")) Then
		
		EndDate = AddMonth(StartDate, 12 * NumberOfPeriods);

	EndIf;
			
	Return EndOfDay(EndDate-OneDay);

EndFunction // Calculate the date of the end of the period()

// Calculates the start date of the period closest to the specified date
//
// Parameters:
//	StartDate - Date - the date by which the nearest start date of the period will be calculated
// 	Periodicity - EnumRef.Periodicity - the value of the "Frequency" enumeration.
//
// Returns:
// 	Date - Start date of the nearest period.
//
Function CalculateStartDateOfNearestPeriod(StartDate, Periodicity) Export
	
	OneDay = 86400;
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
		
		NearestDate = StartDate;
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		
		If StartDate = BegOfWeek(StartDate) Then
			NearestDate = StartDate;
		Else
			NearestDate = EndOfWeek(StartDate) + OneDay;
		EndIf;
		
	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.TenDays")) Then
		
		MonthDay   = Day(StartDate);
		BegOfMonth = BegOfMonth(StartDate);
		
		If MonthDay = 1 Or MonthDay = 11 Or MonthDay = 21 Then
			NearestDate = StartDate;
		ElsIf MonthDay <= 10 Then // The first decade
			NearestDate = BegOfMonth + OneDay * 10;
		ElsIf MonthDay <= 20 Then // The second decade
			NearestDate = BegOfMonth + OneDay * 20;
		Else // The third decade
			NearestDate = EndOfMonth(BegOfMonth) + OneDay;
		EndIf;
		
	ElsIf (Periodicity= PredefinedValue("Enum.Periodicity.Month")) Then
		
		If StartDate = BegOfMonth(StartDate) Then
			NearestDate = StartDate;
		Else
			NearestDate = EndOfMonth(StartDate) + OneDay;
		EndIf;

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Quarter")) Then
		
		If StartDate = BegOfQuarter(StartDate) Then
			NearestDate = StartDate;
		Else
			NearestDate = EndOfQuarter(StartDate) + OneDay;
		EndIf;

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.HalfYear")) Then
		
		BegOfYear      = BegOfYear(StartDate);
		BeginningOfHalfYear = AddMonth(BegOfYear,6);
		
		If StartDate = BeginningOfHalfYear Or StartDate = BegOfYear Then
			NearestDate = StartDate;
		Else
			NearestDate = ?(StartDate > BeginningOfHalfYear, EndOfYear(StartDate) + OneDay, BeginningOfHalfYear);
		EndIf;

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Year")) Then
		
		If StartDate = BegOfYear(StartDate) Then
			NearestDate = StartDate;
		Else
			NearestDate = EndOfYear(StartDate) + OneDay;
		EndIf;

	EndIf;
	
	Return NearestDate;
	
EndFunction // Calculate the date of the beginning of the shortest period()

// Compares the values of the passed structures by the specified properties
// Parameters:
// 	Structure1 - Structure -
// 	Structure2 - Structure -
//	Properties - Array, Structure, String - names of properties to compare against  
// Returns:
// 	Boolean - True if the structures are equal in the values of the passed properties.
//
Function StructuresAreEqual(Structure1, Structure2, Properties = Undefined) Export
	
	ForAllProperties = False;
	
	If TypeOf(Properties) = Type("String") Then
		PropertiesArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Properties,,, True);
	ElsIf Properties <> Undefined Then 
		PropertiesArray = Properties;
	Else
		ForAllProperties = True;
	EndIf;
	
	If ForAllProperties Then
		
		For Each KeyValue In Structure1 Do
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
			If TypeOf(KeyValue.Value) = Type("ValueTable") Then
				Continue;
			EndIf;
#EndIf
			If TypeOf(KeyValue.Value) = Type("Array")
				And Not ArraysAreEqual(KeyValue.Value, Structure2[KeyValue.Key]) Then
				Return False;
			ElsIf (TypeOf(KeyValue.Value) = Type("Structure")
					Or TypeOf(KeyValue.Value) = Type("Map"))
				And Not StructuresAreEqual(KeyValue.Value, Structure2[KeyValue.Key]) Then
				Return False;
			ElsIf Not (TypeOf(KeyValue.Value) = Type("Array")
					Or TypeOf(KeyValue.Value) = Type("Structure")
					Or TypeOf(KeyValue.Value) = Type("Map"))
					And Not KeyValue.Value = Structure2[KeyValue.Key] Then
				Return False;
			EndIf;
		EndDo;
		
	ElsIf TypeOf(PropertiesArray) = Type("Array") Then 
		For Each ArrRow In PropertiesArray Do
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
			If TypeOf(Structure1[ArrRow]) = Type("ValueTable") Then
				Continue;
			EndIf;
#EndIf
			If TypeOf(Structure1[ArrRow]) = Type("Array")
				And Not ArraysAreEqual(Structure1[ArrRow], Structure2[ArrRow]) Then
				Return False;
			ElsIf (TypeOf(Structure1[ArrRow]) = Type("Structure")
					Or TypeOf(Structure1[ArrRow]) = Type("Map"))
				And Not StructuresAreEqual(Structure1[ArrRow], Structure2[ArrRow]) Then
				Return False;
			ElsIf Not (TypeOf(Structure1[ArrRow]) = Type("Array")
					Or TypeOf(Structure1[ArrRow]) = Type("Structure")
					Or TypeOf(Structure1[ArrRow]) = Type("Map"))
					And Not Structure1[ArrRow] = Structure2[ArrRow] Then
				Return False;
			EndIf;
		EndDo;
	ElsIf TypeOf(PropertiesArray) = Type("Structure") Then 
		For Each KeyValue In PropertiesArray Do
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
			If TypeOf(Structure1[KeyValue.Key]) = Type("ValueTable") Then
				Continue;
			EndIf;
#EndIf
			If TypeOf(Structure1[KeyValue.Key]) = Type("Array")
				And Not ArraysAreEqual(Structure1[KeyValue.Key], Structure2[KeyValue.Value]) Then
				Return False;
			ElsIf (TypeOf(Structure1[KeyValue.Key]) = Type("Structure")
					Or TypeOf(Structure1[KeyValue.Key]) = Type("Map"))
				And Not StructuresAreEqual(Structure1[KeyValue.Key], Structure2[KeyValue.Value]) Then
				Return False;
			ElsIf Not (TypeOf(Structure1[KeyValue.Key]) = Type("Array")
					Or TypeOf(Structure1[KeyValue.Key]) = Type("Structure")
					Or TypeOf(Structure1[KeyValue.Key]) = Type("Map"))
					And Not Structure1[KeyValue.Key] = Structure2[KeyValue.Value] Then
				Return False;
			EndIf;
		EndDo;
	EndIf;
	
	Return True;
	
EndFunction

// Compares the values of passed arrays
//
// Parameters:
//	Array1 - Array - 
//	Array2 - Array - 
//	OrderMatters - Boolean - if True, the same values must have the same indexes in the array.
//
// Returns:
//	Boolean - True if the arrays are equal
//
Function ArraysAreEqual(Array1, Array2, OrderMatters = True) Export
	
	If Not Array1.Count() = Array2.Count() Then
		Return False;
	EndIf;
	
	If OrderMatters Then
		
		For IndexOf = 0 To Array1.Count() - 1 Do
			If Not Array1[IndexOf] = Array2[IndexOf] Then
				Return False;
			EndIf;
		EndDo;
		
	Else
		
		For Each CurrentItem In Array1 Do
			If Array2.Find(CurrentItem) = Undefined Then
				Return False;
			EndIf;
		EndDo;
		
	EndIf;
	
	Return True;
	
EndFunction

// Returns a structure containing the keys that are present in both source structures.
//
// Parameters:
// 	Structure1 - Structure -
// 	Structure2 - Structure -
//
// Returns:
// 	Structure - 
//@skip-warning
Function GetSharedKeysOfStructures(Structure1, Structure2) Export
	
	Result = New Structure;
	
	For Each KeyAndValue In Structure1 Do
		If Structure2.Property(KeyAndValue.Key) Then
			Result.Insert(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Checks the structure for the presence of one key or all keys from the passed set at once
//
// Parameters:
// 	Structure - Structure - Auditee
// 	Keys - String - Comma-separated keys
// 	CheckingEverything - Boolean - Indicates whether all keys in the set must be checked.
//
// Returns:
// 	Boolean - Indicates the presence of one or all of the set keys in this structure.
//
Function StructureContainsKeys(Structure, Keys, CheckingEverything=False) Export
	
	RequiredKeys = New Structure(Keys);
	For Each KeyAndValue In RequiredKeys Do
		If CheckingEverything And Not Structure.Property(KeyAndValue.Key) Then
			Return False;
		EndIf;
		If Not CheckingEverything And Structure.Property(KeyAndValue.Key) Then
			Return True;
		EndIf;
	EndDo;
	
	Return CheckingEverything;
	
EndFunction

// String representation of the structure
//
// Parameters:
//  Structure - Structure -
// 
// Returns:
//  String - representation of the transmitted structure in the form "<Key1>: <Value1>; <Key2>: <Value2>".
//
Function StructurePresentation(Structure) Export
	
	RowsArray = New Array;
	For Each KeyValue In Structure Do
		RowsArray.Add(KeyValue.Key + ": " + String(KeyValue.Value));
	EndDo;
	
	Return StrConcat(RowsArray, "; ");
	
EndFunction

// Complements the receiver structure with source structure fields
//
// Parameters:
// 		ReceiverStructure - Structure - Structure to copy fields to
// 		SourceStructure - Structure - Structure to copy fields from
// 		CopyValues - Boolean - True if you need to copy values.
//
Procedure SupplementStructure(ReceiverStructure, SourceStructure, CopyValues=False) Export
	
	For Each Item In SourceStructure Do
		ReceiverStructure.Insert(Item.Key, ?(CopyValues, Item.Value, Undefined));
	EndDo;
	
EndProcedure // Complement the structure()

// Returns the period increased by the number of periods
//
// Parameters:
//	BaseDate - Date - the date that the period is calculated relative to
//	Periodicity - EnumRef.Periodicity - the size of the period
//	NumberOfPeriods - Number - the number of periods for which you need to expand the base.
//                     if = 0, then the period in which the base date is located is returned,
//                     if < 0, then the period corresponding to the previous periods is returned,
//                     if > 0, then the period corresponding to the next periods is returned.
// Returns:
// 	StandardPeriod - 
Function ExtendedPeriod(BaseDate, Periodicity, NumberOfPeriods = 0) Export

	OneDay = 86400;
	Period = New StandardPeriod;
	Period.Variant = StandardPeriodVariant.Custom;

	If Periodicity = PredefinedValue("Enum.Periodicity.Day") Then

		Period.StartDate    = BegOfDay(BaseDate);
		Period.EndDate = EndOfDay(BaseDate);

		If NumberOfPeriods < 0 Then
			Period.EndDate = Period.StartDate - 1;
			Period.StartDate    = Period.StartDate + OneDay * NumberOfPeriods;
		ElsIf NumberOfPeriods > 0 Then
			Period.StartDate    = Period.EndDate + 1;
			Period.EndDate = Period.EndDate + OneDay * NumberOfPeriods;
		EndIf;

	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Week") Then

		Period.StartDate    = BegOfWeek(BaseDate);
		Period.EndDate = EndOfWeek(BaseDate);

		If NumberOfPeriods < 0 Then
			Period.EndDate = Period.StartDate - 1;
			Period.StartDate    = Period.StartDate + OneDay * 7 * NumberOfPeriods;
		ElsIf NumberOfPeriods > 0 Then
			Period.StartDate    = Period.EndDate + 1;
			Period.EndDate = Period.EndDate + OneDay * 7 * NumberOfPeriods;
		EndIf;

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.TenDays")) Then
		
		MonthDay = Day(BaseDate);
		If MonthDay <= 10 Then
			NumberOfDecadeIsBasic = 1;
		ElsIf MonthDay <= 20 Then
			NumberOfDecadeIsBasic = 2;
		Else
			NumberOfDecadeIsBasic = 3;
		EndIf;
		
		If NumberOfPeriods >= 0 Then
			
			DecadeNumber = NumberOfDecadeIsBasic + NumberOfPeriods + 1;
			ShiftingMonths = Int((DecadeNumber - 1) / 3);
			DecadeNumber = DecadeNumber - 3 * ShiftingMonths;
			
			StartDate = BegOfMonth(BaseDate);
			If NumberOfDecadeIsBasic = 2 Then
				StartDate = StartDate + 9 * OneDay;
			ElsIf NumberOfDecadeIsBasic = 3 Then
				StartDate = StartDate + 19 * OneDay;
			EndIf;
			Period.StartDate = StartDate;
			
			EndDate = AddMonth(BegOfMonth(BaseDate), ShiftingMonths);
			If DecadeNumber = 2 Then
				EndDate = EndDate + 9 * OneDay;
			ElsIf DecadeNumber = 3 Then
				EndDate = EndDate + 19 * OneDay;
			EndIf;
			Period.EndDate = EndDate - 1;
			
		Else
			
			DecadeNumber = NumberOfDecadeIsBasic + NumberOfPeriods;
			ShiftingMonths = -1 - Int((-DecadeNumber) / 3);
			DecadeNumber = DecadeNumber - 3 * ShiftingMonths;
			StartDate = AddMonth(BegOfMonth(BaseDate), ShiftingMonths);
			If DecadeNumber = 2 Then
				StartDate = StartDate + 9 * OneDay;
			ElsIf DecadeNumber = 3 Then
				StartDate = StartDate + 19 * OneDay;
			EndIf;
			Period.StartDate = StartDate;
			
			EndDate = BegOfMonth(BaseDate);
			If NumberOfDecadeIsBasic = 2 Then
				EndDate = EndDate + 9 * OneDay;
			ElsIf NumberOfDecadeIsBasic = 3 Then
				EndDate = EndDate + 19 * OneDay;
			EndIf;
			Period.EndDate = EndDate - 1;
			
		EndIf;
		
	ElsIf (Periodicity= PredefinedValue("Enum.Periodicity.Month")) Then

		Period.StartDate    = BegOfMonth(BaseDate);
		Period.EndDate = EndOfMonth(BaseDate);

		If NumberOfPeriods < 0 Then
			Period.EndDate = Period.StartDate - 1;
			Period.StartDate = AddMonth(Period.StartDate, NumberOfPeriods);
		ElsIf NumberOfPeriods > 0 Then
			Period.StartDate = Period.EndDate + 1;
			Period.EndDate = AddMonth(Period.EndDate, NumberOfPeriods);
		EndIf;

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Quarter")) Then

		Period.StartDate    = BegOfQuarter(BaseDate);
		Period.EndDate = EndOfQuarter(BaseDate);

		If NumberOfPeriods < 0 Then
			Period.EndDate = Period.StartDate - 1;
			Period.StartDate    = AddMonth(Period.StartDate, 3*NumberOfPeriods);
		ElsIf NumberOfPeriods > 0 Then
			Period.StartDate    = Period.EndDate + 1;
			Period.EndDate = AddMonth(Period.EndDate, 3*NumberOfPeriods);
		EndIf;

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.HalfYear")) Then

		If Month(BaseDate) < 7 Then
			Period.StartDate    = BegOfYear(BaseDate);
			Period.EndDate = AddMonth(EndOfYear(BaseDate), - 6);
		Else
			Period.StartDate    = AddMonth(BegOfYear(BaseDate), 6);
			Period.EndDate = EndOfYear(BaseDate);
		EndIf;

		If NumberOfPeriods < 0 Then
			Period.EndDate = Period.StartDate - 1;
			Period.StartDate    = AddMonth(Period.StartDate, 6*NumberOfPeriods);
		ElsIf NumberOfPeriods > 0 Then
			Period.StartDate    = Period.EndDate + 1;
			Period.EndDate = AddMonth(Period.EndDate, 6*NumberOfPeriods);
		EndIf;

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Year")) Then

		Period.StartDate    = BegOfYear(BaseDate);
		Period.EndDate = EndOfYear(BaseDate);

		If NumberOfPeriods < 0 Then
			Period.EndDate = Period.StartDate - 1;
			Period.StartDate    = AddMonth(Period.StartDate, 12*NumberOfPeriods);
		ElsIf NumberOfPeriods > 0 Then
			Period.StartDate    = Period.EndDate + 1;
			Period.EndDate = AddMonth(Period.EndDate, 12*NumberOfPeriods);
		EndIf;

	EndIf;

	Return Period;

EndFunction

// Checks the string with the email address for correctness of the entered data
//
// Parameters:
//  VerifiedAddress - String - contains a string with the email address to check.
//  
// Returns:
//   Boolean - False if the check was successful, True in the opposite case.
//
Function CheckYourEmailAddress(VerifiedAddress) Export
	
	Cancel = False;
	AddressToVerify = VerifiedAddress;
	
	Try
		Result =  CommonClientServer.ParseStringWithEmailAddresses(AddressToVerify);	 
	Except 		
		Cancel = True;
	EndTry;
	
	If Not Cancel Then
		If Result.Count() = 0 Then
			Cancel =  True;
		Else	
			AddressToVerify = Result[0].Address;
			If StrOccurrenceCount(AddressToVerify,"@") <> 1 Then 
				Cancel = True;
			Else
				DomainAddress = Right(AddressToVerify, StrLen(AddressToVerify) - StrFind(AddressToVerify,"@"));
				If StrLen(DomainAddress) > 0 Then
					If StrOccurrenceCount(DomainAddress,".") < 1 Or Left(DomainAddress,1) = "." Or Right(DomainAddress,1) = "." Then
						Cancel = True;
					EndIf;
				Else
					Cancel = True;
				EndIf;
			EndIf;
		EndIf;	
	EndIf;	
	
	Return Cancel;
	
EndFunction // Check the filling of the Mail address() 

// Calculates the ID value from a string in accordance with the ID naming rules.
// 
// Parameters:
// 	RwName - String - 
// 	
// Returns:
// 	String - An identifier that conforms to the rules for naming identifiers.
//
Function GetID(RwName) Export
	
	Separators	=  " .,+,-,/,*,?,=,<,>,(,)%!@#$%&*""№:;{}[]?()\|/`~'^_";
	
	Id = "";
	HadSpecialChar = False;
	
	For CharNum = 1 To StrLen(RwName) Do
		
		Char = Mid(RwName, CharNum, 1);
		
		If StrFind(Separators, Char) <> 0 Then
			HadSpecialChar = True;
		ElsIf HadSpecialChar Then
			HadSpecialChar = False;
			Id = Id + Upper(Char);
		Else
			Id = Id + Char;
		EndIf;
		
	EndDo;
	
	Return Id;
	
EndFunction // Get the identifier()

// Fills all rows of the specified columns in the collection with the specified value
//
// Parameters:
// 		Collection - FormDataCollection - Collection for filling in rows
// 		Value - Arbitrary - Value for substitution
// 		Columns - String - A string of comma-separated column names in the collection.
//
Procedure FillInCollectionPropertyValues(Collection, Value, Columns) Export
	
	FillingStructure = New Structure(Columns);
	For Each Column In FillingStructure Do
		FillingStructure[Column.Key] = Value;
	EndDo;
	
	For Counter = 0 To Collection.Count() - 1 Do
		FillPropertyValues(Collection[Counter], FillingStructure);
	EndDo;
	
EndProcedure // Fill in the values of the Column Collection()

// Used for converting pages
//
// Parameters:
//  LineToConvert - String - The string from which you want to remove the block
//  BoundingString - String - the limiter block that needs to be removed.
//
Procedure RemoveSubstringFromString(LineToConvert, BoundingString) Export
	
	If StrFind(LineToConvert, BoundingString) = 0 Then
		Return;
	EndIf;
	
	LengthOfBoundingString = StrLen(BoundingString);
	IndexOfFirstOccurrence = StrFind(LineToConvert, BoundingString);
	LeftPart =  Left(LineToConvert, IndexOfFirstOccurrence-1);
	RightPartOfLineIsReadyForProcessing = Right(LineToConvert, StrLen(LineToConvert) - IndexOfFirstOccurrence - LengthOfBoundingString);
	IndexOfSecondOccurrence = StrFind(RightPartOfLineIsReadyForProcessing, BoundingString);
	RightPart = Right(RightPartOfLineIsReadyForProcessing,StrLen(RightPartOfLineIsReadyForProcessing) - IndexOfSecondOccurrence -LengthOfBoundingString + 1);
	
	LineToConvert = LeftPart +  RightPart;
	
EndProcedure

// The function performs a proportional distribution of the amount according
// to the specified distribution coefficients.
//
// Parameters:
//		InitAmount - Number -distributed amount
//		KoefArray - Array of Number - distribution coefficient
//		Accuracy - Number - rounding precision in the distribution. Optional.
//
//	Returns:
//		Array of Number - an array of dimension equal to the array of coefficients contains
//			sums in accordance with the weight of the coefficient (from the array of coefficients)
//          If the distribution failed (sum = 0, number of coef. = 0,
//          or total weight of coef. = 0), then the value is returned Undefined.
//
Function DistributeProportionally(Val InitAmount, KoefArray, Val Accuracy = 2) Export

	If KoefArray.Count() = 0 Or InitAmount = 0 Or InitAmount = Null Then
		Return Undefined;
	EndIf;

	IndexOfMax = 0;
	MaxVal   = 0;
	RasprSum = 0;
	KoefSum  = 0;

	For Counter = 0 To KoefArray.Count() - 1 Do

		ModuleNumbers = ?(KoefArray[Counter] > 0, KoefArray[Counter], - KoefArray[Counter]);

		If MaxVal < ModuleNumbers Then
			MaxVal = ModuleNumbers;
			IndexOfMax = Counter;
		EndIf;

		KoefSum = KoefSum + KoefArray[Counter];

	EndDo;

	If KoefSum = 0 Then
		Return Undefined;
	EndIf;

	ArrayOfAmounts = New Array(KoefArray.Count());

	For Counter = 0 To KoefArray.Count() - 1 Do
		ArrayOfAmounts[Counter] = Round(InitAmount * KoefArray[Counter] / KoefSum, Accuracy, 1);
		RasprSum = RasprSum + ArrayOfAmounts[Counter];
	EndDo;

	// The rounding errors are attributed to the coefficient with the maximum weight
	If Not RasprSum = InitAmount Then
		ArrayOfAmounts[IndexOfMax] = ArrayOfAmounts[IndexOfMax] + InitAmount - RasprSum;
	EndIf;

	Return ArrayOfAmounts;

EndFunction // Distribute proportionally()

// Checks that an external user is authorized
//
// Returns:
//   Boolean   - True if an external user is authorized. False, otherwise.
//
Function AnExternalUserIsAuthorized() Export

	Return TypeOf(UsersClientServer.AuthorizedUser()) =  Type("CatalogRef.ExternalUsers");

EndFunction

// The function generates a list of values containing the time values calculated
// at the specified interval.
//
// Parameters:
//	CurrentValue - Date - initial time value
//	Interval - Number - the default interval for filling in the list is one hour.
//
// Returns:
// 	ValueList -
Function TimeList(Val CurrentValue = '00010101000000', Interval = 3600) Export
	
	WorkdayBeginning      = '00010101000000';
	WorkdayEnd   = '00010101235959';

	TimesList = New ValueList;
	WorkdayBeginning = BegOfHour(BegOfDay(CurrentValue)
		+ Hour(WorkdayBeginning) * 3600
		+ Minute(WorkdayBeginning)*60);
	WorkdayEnd = EndOfHour(BegOfDay(CurrentValue)
		+ Hour(WorkdayEnd) * 3600
		+ Minute(WorkdayEnd)*60);

	ListTime = WorkdayBeginning;
	While BegOfHour(ListTime) <= BegOfHour(WorkdayEnd) Do
		If Not ValueIsFilled(ListTime) Then
			TimePresentation = "00:00";
		Else
			TimePresentation = Format(ListTime, NStr("vi = 'ДФ=''ЧЧ:мм''';
													|ru = 'ДФ=''ЧЧ:мм''';
													|en = 'DF=''HH:mm'''; fa = 'DF=''HH:mm''';
													|it = 'ДФ=''ЧЧ:мм''';
													|pl = 'DF=''GG:mm''';
													|tr = 'DF=''HH:mm'''"));
		EndIf;

		TimesList.Add(ListTime, TimePresentation);

		ListTime = ListTime + Interval;
	EndDo;
	
	Return TimesList;
	
EndFunction

// The function converts a string to a plural
//
// Parameters: 
//  Word1 - String - form of the word including ("Cabinet")
//  Word2 - String - the word form for numbers 2-4 ("Cabinet")
//  Word3 - String - word form for numbers 5-10 ("cabinets")
//  Integer1 - Number - integer.
//
// Returns:
//  String - one of the lines, depending on the parameter, is integer.
//
// Description:
//  It is intended for forming the "correct" signature for numerals.
//
Function InPlural(Word1, Word2, Word3, Val Integer1) Export
	
	// Let's change the sign of an integer, otherwise negative numbers will be converted incorrectly.
	If Integer1 < 0 Then
		Integer1 = -1 * Integer1;
	EndIf;
	
	If Integer1 <> Int(Integer1) Then 
		// for non-integers , it is always the second form
		Return Word2;
	EndIf;
	
	// Balance
	Balance = Integer1%10;
	If (Integer1 >10) And (Integer1<20) Then
		// for the second ten - always the third form
		Return Word3;
	ElsIf Balance=1 Then
		Return Word1;
	ElsIf (Balance>1) And (Balance<5) Then
		Return Word2;
	Else
		Return Word3;
	EndIf;

EndFunction

// Determines whether the counterparty is a legal entity
//
// Parameters:
//	CompanyIndividual - EnumRef.CompanyIndividual - type of counterparty.
//
// Returns:
//  Boolean - True if it is a legal entity, False in the opposite case.
//
Function ThisIsYurFace(CompanyIndividual) Export
	
	If TypeOf(CompanyIndividual) = Type("EnumRef.CompanyIndividual") Then
		Return CompanyIndividual = PredefinedValue("Enum.CompanyIndividual.BusinessEntity");
	Else
		Return CompanyIndividual = PredefinedValue("Enum.LegalEntityIndividual.Entity")
			Or CompanyIndividual = PredefinedValue("Enum.LegalEntityIndividual.LegalEntityNonResident");
	EndIf;

EndFunction

// Returns a word in different declensions (according to the number)
// The main purpose is to use units of measurement in forms
// for various numerical fields for declination of inscriptions.
//
// Parameters:
//	NumberForDeclension - Number - the number determines the declination.
//	NumerationItemOptions - String - the parameters of the calculus subject as in the numerical method.
//
// Returns:
//  String - the word is in the correct declension.
//
Function DeclensionOfWord(NumberForDeclension, NumerationItemOptions) Export
	
	Result = "";
	WordInWords = NumberInWords(NumberForDeclension, , NumerationItemOptions);
	ParametersArray = StrSplit(NumerationItemOptions, ",", False);
	WordLengthInWords = StrLen(WordInWords);
	
	For Each Parameter In ParametersArray Do
		Parameter = TrimAll(Parameter);
		ParameterStart = StrFind(WordInWords, Parameter);
		If ParameterStart > 0 Then
			LengthParameter = StrLen(Parameter);
			ParameterEnd = LengthParameter + ParameterStart - 1;
			If StrFind(WordInWords, " " + Parameter + " ") > 0 
				Or (ParameterStart = 1 And Mid(WordInWords, ParameterEnd + 1, 1) = " ")
				Or ((WordLengthInWords - LengthParameter) = (ParameterStart-1) And Mid(WordInWords, ParameterStart - 1, 1) = " ") Then
				Return Parameter;
			EndIf;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Returns a string representation of the period.
//
// Parameters:
//  RegistrationPeriod - Date   - Date within the month or quarter, the performance of which is necessary to obtain
//  CalendarPeriod - String - "Month" or "Quarter".
//
// Returns:
//  String - Representation of the month or quarter within which the Registration period value is located.
//
Function GetPresentationOfRegistrationPeriod(RegistrationPeriod, CalendarPeriod = "Month") Export

	If Upper(CalendarPeriod) = "MONTH" Then
		Return Format(RegistrationPeriod, NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
												|ru = 'ДФ=''MMMM yyyy''';
												|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
												|it = 'ДФ=''ММММ гггг''';
												|pl = 'DF=''MMMM yyyy''';
												|tr = 'ДФ=''ММММ гггг'''"))
	ElsIf Upper(CalendarPeriod) = "QUARTER" Then
		Return PeriodPresentation(BegOfQuarter(RegistrationPeriod), EndOfQuarter(RegistrationPeriod));
	EndIf;

EndFunction

// Complements the table of values with values from the array Array.
//
// Parameters:
//  DestinationTable     - ValueTable - table to fill in with values from the array;
//  Array              - Array - array of values to fill in the table;
//  FieldName             - String - name of the value table field to load values from the array into.
//  DefaultValues - Structure - names of fields and their values that will be used to fill in each added row.
// 
Procedure SupplementTableFromArray(DestinationTable, Array, FieldName, DefaultValues = Undefined) Export

	For Each Value In Array Do
		NewRow = DestinationTable.Add();
		NewRow[FieldName] = Value;
		If DefaultValues <> Undefined Then
			FillPropertyValues(NewRow, DefaultValues, , ?(DefaultValues.Property(FieldName), FieldName, ""));
		EndIf; 
	EndDo;
	
EndProcedure

// Supplements the receiver value table with data from the source value table.
//
// Parameters:
//  SourceTable1	 - ValueTable	 - table from which rows will be taken to fill in;
//  DestinationTable	 - ValueTable	 - table to add rows from the source table to.
//  DefaultValues - Structure      - key - name of the column in the receiver table, value - default value
//  PriorityOfDefaultValues - Boolean - indicates that the passed defaults will take priority over data from the source table.
//
// Returns:
//  Array of ValueTableRow - contains the added lines.
//
//@skip-warning
Function SupplementTable(Val SourceTable1, DestinationTable, DefaultValues = Undefined, PriorityOfDefaultValues = False) Export
	
	AddedRows = New Array;
	For Each SourceTableRow In SourceTable1 Do
		NewRow = DestinationTable.Add();
		If DefaultValues <> Undefined Then
			FillPropertyValues(NewRow, DefaultValues);
			
			If PriorityOfDefaultValues Then
				FillPropertyValues(SourceTableRow, DefaultValues);
			EndIf;
		EndIf;
		FillPropertyValues(NewRow, SourceTableRow);
		AddedRows.Add(NewRow);
	EndDo;
	
	Return AddedRows;
	
EndFunction

// Supplements the receiver value table with data from the source value table.
//
// Parameters:
//  ValueTable	 - ValueTable	 - table where I will change data
//  SourceColumn_	 - String	 - column to extract values from
//  ColumnReceiver	 - String	 - the column where the values will be set.
// 
Procedure CopyValuesFromColumnToColumn(ValueTable, SourceColumn_, ColumnReceiver) Export
	
	For Each ValueTableRow In ValueTable Do
		ValueTableRow[ColumnReceiver] = ValueTableRow[SourceColumn_];
	EndDo;
	
EndProcedure

// Fills in the values of the receiver properties based on the values of the source properties, if these properties are not filled in in the receiver.
//
// Parameters:
//  Receiver - Structure, Map, FixedStructure, FixedMap, Arbitrary  - collection of data structures, property values to be filled in.
//  Source		 - Structure, Map, FixedStructure, FixedMap - a collection of data structures
// 												that is the source of property values to be filled in in the receiver.
//  ListOfProperties	 - String,Array,Undefined - comma-separated property names or an array of property names to fill in.
//													If passed Undefined, all matching properties in the receiver and source are filled in.
//  ExcludeProperties - String,Array,Undefined - comma-separated property names or an array of property names to exclude from the padding.
//													If passed Undefined, all properties are filled in.
//
Procedure FillInValuesOfEmptyProperties(Receiver, Source, ListOfProperties = Undefined, ExcludeProperties = Undefined) Export
	
	If ExcludeProperties = Undefined Then
		ExcludingArrayProperties = New Array;
	ElsIf TypeOf(ExcludeProperties) = Type("String") Then	
		ExcludingArrayProperties = StrSplit(ExcludeProperties, ",");
	Else
		ExcludingArrayProperties = ExcludeProperties;
	EndIf;
		
	If ListOfProperties = Undefined Then
		
		ReceiverObject_ = Not (TypeOf(Receiver) = Type("Structure")
							Or TypeOf(Receiver) = Type("Map")
							Or TypeOf(Receiver) = Type("FixedStructure")
							Or TypeOf(Receiver) = Type("FixedMap"));
		
		For Each KeyValue In Source Do
			If ExcludingArrayProperties.Find(KeyValue.Key) <> Undefined Then
				Continue;
			EndIf;
			
			ThereIsProperty = ?(ReceiverObject_,
							HasObjectAttribute(Receiver, KeyValue.Key),
							Receiver.Property(KeyValue.Key));
			
			If ThereIsProperty
				And ((TypeOf(Receiver[KeyValue.Key]) = Type("Boolean")
						And Not Receiver[KeyValue.Key])
					Or Not ValueIsFilled(Receiver[KeyValue.Key])) Then
				Receiver[KeyValue.Key] = KeyValue.Value;
			EndIf;
			
		EndDo;
		
	Else
		
		If TypeOf(ListOfProperties) = Type("String") Then	
			ListOfArrayProperties = StrSplit(ListOfProperties, ",");
		Else
			ListOfArrayProperties = ListOfProperties;
		EndIf;
		
		For Each ArrRow In ListOfArrayProperties Do
			If ExcludingArrayProperties.Find(ArrRow) <> Undefined Then
				Continue;
			EndIf;
			
			If (TypeOf(Receiver[ArrRow]) = Type("Boolean")
						And Not Receiver[ArrRow])
					Or Not ValueIsFilled(Receiver[ArrRow]) Then
				Receiver[ArrRow] = Source[ArrRow];
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Clears the listed object properties.
//
// Parameters:
//	Object	 - Arbitrary		 - the object information database for which you want to clear the values of the properties.
//	Properties - String, Array	 - property names separated by commas or an array of names.
//
Procedure ClearPropertyValues(Object,Properties) Export
	
	If TypeOf(Properties) = Type("String") Then
		RowsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Properties);
	Else
		RowsArray = Properties;
	EndIf;
	
	For Each Property In RowsArray Do
		Object[Property] = Undefined;
	EndDo;
	
EndProcedure

// Converts time from the specified time units to seconds
//
// Parameters:
//  Time - Number - Time.
//  TimeUnitOfMeasure	- EnumRef.TimeMeasureUnits - the unit of time.
// 
// Returns:
//   - Number - time in seconds
//
Function TimeInSeconds(Time, TimeUnitOfMeasure) Export
	
	If Time = 0 Then
		
		Return 0;
		
	EndIf;
	
	If TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Days1") 
		Or TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Day") Then
		
		TimeInSeconds = Time * 86400; // 60 * 60 * 24
		
	ElsIf TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Minute") Then
		
		TimeInSeconds = Time * 60;
		
	ElsIf TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Hour") Then
		
		TimeInSeconds = Time * 3600; //60 * 60;
		
	ElsIf TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Second") Then
		
		TimeInSeconds = Time;
		
	Else
		
		TimeInSeconds = 0;
		
	EndIf;

	Return TimeInSeconds;
	
EndFunction

// Adds the time to the date.
// 
// Parameters:
// 	Begin - Date - the date to add the time to
// 	Time - Number - Time.
// 	TimeUnitOfMeasure - EnumRef.TimeMeasureUnits - the unit of time.
// 	
// Returns:
// 	Date - 
Function AddTimeToDate(Begin, Time, TimeUnitOfMeasure) Export

	If TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Second")
		Or TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Minute")
		Or TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Hour")
		Or TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Day")
	 	Or TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Days1") Then
			
		NewDate = Begin + TimeInSeconds(Time, TimeUnitOfMeasure);
		
	ElsIf TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Month") Then
		
		NewDate = AddMonth(Begin, Time);
		
	ElsIf TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Year") Then
		
		NewDate = AddMonth(Begin, Time*12);

	Else
		
		NewDate = '00010101';
		
	EndIf;
	
	Return NewDate;
	
EndFunction

// Creates a type Descriptor object containing the String type.
//
// Parameters:
//  StringLength - Number - string length.
//
// Returns:
//  TypeDescription - description of the String type.
//
Function StringTypeDetails(StringLength) Export
	
	Return New TypeDescription("String", , New StringQualifiers(StringLength));
	
EndFunction

// Creates a type Description object containing the Number type.
//
// Parameters:
//  Digits - Number - the total number of digits (number of digits
//                        the integer part plus the number of digits of the fractional part).
//  FractionDigits - Number - the number of digits of the fractional part.
//  NumberSign - AllowedSign - valid sign of the number.
//
// Returns:
//  TypeDescription - description of the Number type.
//
Function TypeDescriptionNumber(Digits, FractionDigits = 0, Val NumberSign = Undefined) Export
	
	If NumberSign = Undefined Then 
		NumberSign = AllowedSign.Any;
	EndIf;
	
	Return New TypeDescription("Number", New NumberQualifiers(Digits, FractionDigits, NumberSign));
	
EndFunction

// Rounds the number to the nearest larger value.
// 
// Parameters:
//  Number       - Number - Any real number that you want to round up.
//  Digits - Number - The number of digits to which the number is rounded. The default value is 0.
// 
// Returns:
// 	Number
//  
Function RoundCeiling(Number, Digits = 0) Export
	
	If TypeOf(Digits) <> Type("Number") Or Digits <> Int(Digits) Then
		Raise NStr("vi = 'Độ sâu bit phải là số nguyên!';
					|ru = 'Разрядность должна быть целым числом!';
					|en = 'Bitness must be an integer.'; fa = 'Bitness must be an integer.';
					|it = 'Разрядность должна быть целым числом!';
					|pl = 'Bitness must be an integer.';
					|tr = 'Bit genişliği bir tamsayı olmalıdır!'");
	EndIf;
	
	Move = Pow(10, Digits);
	
	NumberWithShift  = Number * Move;
	IntegerPartOfNumber = Int(NumberWithShift);
	
	If NumberWithShift - IntegerPartOfNumber > 0  Then
		IntegerPartOfNumber = IntegerPartOfNumber + 1;
	EndIf;
	
	Return IntegerPartOfNumber / Move;
	
EndFunction

// Rounds the number to the nearest smaller value.
// 
// Parameters:
//  Number       - Number - Any real number that you want to round down.
//  Digits - Number - The number of digits to which the number is rounded. The default value is 0.
// 
// Returns:
// 	Number
//  
Function RoundFloor(Number, Digits = 0) Export
	
	If TypeOf(Digits) <> Type("Number") Or Digits <> Int(Digits) Then
		Raise NStr("vi = 'Độ sâu bit phải là số nguyên!';
					|ru = 'Разрядность должна быть целым числом!';
					|en = 'Bitness must be an integer.'; fa = 'Bitness must be an integer.';
					|it = 'Разрядность должна быть целым числом!';
					|pl = 'Bitness must be an integer.';
					|tr = 'Bit genişliği bir tamsayı olmalıdır!'");
	EndIf;
	
	Move = Pow(10, Digits);
	
	NumberWithShift  = Number * Move;
	IntegerPartOfNumber = Int(NumberWithShift);
	
	If NumberWithShift - IntegerPartOfNumber < 0  Then
		IntegerPartOfNumber = IntegerPartOfNumber - 1;
	EndIf;
	
	Return IntegerPartOfNumber / Move;
	
EndFunction

// Converts a string that lists the names of variables (columns/elements, etc.) separated by commas into an array
// 
// Parameters:
//  StringOfNames - String - Any string with a comma-separated list of names that can be converted to a structure using "New Structure (String name);"
// 
// Returns:
// 	Array of String
// 
Function StringOfNamesInArray(StringOfNames) Export
	
	ReturnValue = New Array;
	
	For Each KeyAndValue In New Structure(StringOfNames) Do
		ReturnValue.Add(KeyAndValue.Key);
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// Checks the line with the site address for the correctness of the entered data
//
// Parameters:
//  Address - String - contains a string with the site address that needs to be checked.
//  
// Returns:
//   Boolean - False if the check was successful, True in the opposite case.
//
Function CheckSiteAddress(Address) Export
	Cancel = False;

	// Checking for string type and the absence of an empty value
	If TypeOf(Address) <> Type("String") Or IsBlankString(TrimAll(Address)) Then
		Cancel = True;
	EndIf;
	
	// URI parsing using the BSP function
	Try
		URIStructure = CommonClientServer.URIStructure(Address);
	Except
		Cancel = True;
	EndTry;
	
	// Checking the circuit
	Schema = URIStructure.Schema; 
	If ValueIsFilled(Schema) Then
		If Schema <> "http" And Schema <> "https" Then
			Cancel = True;
		EndIf;  
	EndIf;
	
	Host = Lower(URIStructure.Host); 
	
	// Verification for www. 
	If StrFind(Host, "www.") = 1 Then
		ArrayOfValues = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Host,".");
		If ArrayOfValues.Count() < 3 Then
			Cancel = True;
		EndIf;
	EndIf;
	
	// Checking two points in a row
	If StrFind(Host, "..") > 0 Then
		Cancel = True;
	EndIf;
	
	// Space check
	If StrFind(Host, " ") > 0 Then
		Cancel = True;
	EndIf; 
	
	// Checking the host for a hotspot
	If StrFind(Host, ".") = 0 Then
		Cancel = True;
	EndIf;
	
	Return Cancel;
	
EndFunction

#EndRegion

#Region MethodsForWorkingWithObjectDetails

// Checks whether an arbitrary object has a prop with the specified name.
//
// Returns:
// 	Boolean -
Function HasObjectAttribute(Object, AttributeName) Export
	
	UniqueKey   = New UUID;
	AttributeStructure = New Structure(AttributeName, UniqueKey);

	FillPropertyValues(AttributeStructure, Object);
	
	Return AttributeStructure[AttributeName] <> UniqueKey;
	
EndFunction

// Returns the form table that the element is subordinate to.
// If the element is not subordinate to the form table, it returns Undefined.
//
// Parameters:
//	Item - FormField - Form element
//	
// Returns:
// 	FormTable, Undefined - form table
//
Function ElementShapeTable(Item) Export
	
	If TypeOf(Item.Parent) = Type("FormTable") Then
		Return Item.Parent;
	ElsIf TypeOf(Item.Parent) = Type("FormGroup")
		And Item.Parent.Type = FormGroupType.ColumnGroup Then
		Return ElementShapeTable(Item.Parent)
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns the value of the form or object's props along the path specified as a string.
//
// Parameters:
//	Object - DocumentObject, CatalogObject, ClientApplicationForm - An object or form from which you want to retrieve data
//	DataPath - String - Data path, such as " Object.Contractor"
//	RowID - String - Unique row ID for the case of getting data from a table in a table.
//	MeaningOfAbsence - Arbitrary - If the data path is empty or contains a reference to the Attribute of an empty value, this value is returned
//	
// Returns:
// 	Arbitrary - the value of the props
// 
Function DataAlongWay(Object, Val DataPath, Val RowID = Undefined, MeaningOfAbsence = Undefined) Export
	
	If DataPath = "" Then
		Return MeaningOfAbsence;
	ElsIf TypeOf(DataPath) <> Type("String") Then
		Return DataPath;
	EndIf;
	
	DataPathParts = StrSplit(DataPath, ".", False);
	Data = DataOnPartsOfPath(Object, DataPathParts, RowID, MeaningOfAbsence);
	
	Return Data;
	
EndFunction

// Returns the object and property name for assigning data along the path specified as a string.
//
// Parameters:
//	Object - DocumentObject, CatalogObject, ClientApplicationForm - An object or form from which you want to retrieve data
//	DataPath - String - Data path, such as " Object.Contractor"
//	RowID - String - Unique row ID for the case of getting data from a table in a table.
//
// Returns:
// 	Structure - structure with keys:
//      * Data - Arbitrary - Object to assign data to
//      * Name - String - Name of the property to assign
//
Function DataForAssignment(Object, DataPath, RowID = Undefined) Export
	
	If DataPath = "" Or TypeOf(DataPath) <> Type("String") Then
		Return Undefined;
	EndIf;
	
	DataPathParts = StrSplit(DataPath, ".", False);
	AttributeName = DataPathParts[DataPathParts.Count()-1];
	DataPathParts.Delete(DataPathParts.Count()-1);
	Data = DataOnPartsOfPath(Object, DataPathParts, RowID);
	
	Return New Structure("Data, Name", Data, AttributeName);
	
EndFunction

#EndRegion

#Region AuxiliaryProceduresForWorkingWithForms

// Sets the value of the form element property if it finds the element on the form
//
// Parameters:
//  FormItems - FormAllItems - the form elements that contain the desired element.
//  TagName   - String - the name of the element you are looking for.
//  PropertyName   - String - the name of the property to set the value for.
//  Value      - Arbitrary - the value to be set
//  InstallForSubordinates - Boolean - set the same property for the subordinate elements of the desired element.
//
Procedure SetFormItemProperty(FormItems, TagName, PropertyName, Value, InstallForSubordinates = False) Export
	
	Item = FormItems.Find(TagName);
	If Item = Undefined Then
		Return;
	EndIf;
	
	If Lower(PropertyName) = Lower("ReadOnly")
	And TypeOf(Item) = Type("FormButton") Then
		ItemPropertyName = "Enabled";
		PropertyValue    = Not Value;
	Else
		ItemPropertyName = PropertyName;
		PropertyValue    = Value;
	EndIf;
	
	If Lower(PropertyName) = Lower("ExtendedTooltip") Then
		Item.ExtendedTooltip.Title = Value;
	Else
		If Item[ItemPropertyName] <> PropertyValue Then
			Item[ItemPropertyName] = PropertyValue;
		EndIf;
	EndIf;
	
	TypesOfFormElementsWithSubordinateElements = New TypeDescription("ClientApplicationForm, FormGroup, FormTable");
	
	If InstallForSubordinates And TypesOfFormElementsWithSubordinateElements.ContainsType(TypeOf(Item)) Then
		ChildItems = Item.ChildItems; // Array of FormField - 
		For Each SubordinateItem In ChildItems Do
			SetFormItemProperty(FormItems, SubordinateItem.Name, PropertyName, Value, True);
		EndDo;
 	EndIf;
 	
EndProcedure // Set the property of the form element()

// Sets the value of the form elements property if it finds an element on the form
//
// Parameters:
//  FormItems  - FormAllItems - the form elements that contain the desired element.
//  ItemsNames - Array, String, Structure - names of the elements to search for.
//  PropertyName    - String - the name of the property to set the value for.
//  Value       - Arbitrary - the value to be set
//  InstallForSubordinates - Boolean - set the same property for the subordinate elements of the search elements.
//
Procedure SetPropertyOfFormElements(FormItems, ItemsNames, PropertyName, Value, InstallForSubordinates = False) Export
	
	If TypeOf(ItemsNames) = Type("Array") Then
		
		For Each TagName In ItemsNames Do
			SetFormItemProperty(FormItems, TagName, PropertyName, Value, InstallForSubordinates);
		EndDo
		
	Else
		
		If TypeOf(ItemsNames) = Type("String") Then
			StructureOfElementNames = New Structure(ItemsNames);
		Else
			StructureOfElementNames = ItemsNames;
		EndIf;
		
		For Each TagName In StructureOfElementNames Do
			SetFormItemProperty(FormItems, TagName.Key, PropertyName, Value, InstallForSubordinates);
		EndDo
		
	EndIf;
	
EndProcedure // Set the properties of the form elements()

// The procedure fills in an array of unverifiable details with values that are not used for the selected business operation
// of the document.
//
// Parameters:
//	ArrayOfAllProps - Array - Array of all document details
//	ArrayOfOperationDetails - Array - Array of document details that relate to the business operation of the document
//	NotCheckedAttributeArray - Array - Array of object details that do not require verification.
//
Procedure FillInArrayOfUnverifiableBankingDetails(ArrayOfAllProps, ArrayOfOperationDetails, NotCheckedAttributeArray) Export
	
	For Each ArrayElement In ArrayOfAllProps Do
		
		// If the account details are not used for a business transaction, we exclude this account from verification.
		If ArrayOfOperationDetails.Find(ArrayElement) = Undefined Then
			NotCheckedAttributeArray.Add(ArrayElement);
		EndIf;
		
	EndDo;
	
EndProcedure // Fill in the mass of unverified Requirements()

// Returns the document representation based on the prefixing parameters set in the IB
//
// Parameters:
// 		Description - String - String representation of the document type name
// 		Number - String - document number
// 		Date - Date - document date.
//
// Returns:
// 		String - Presentation of a document with an overridden name, excluded zeros from the number and a localized date.
//
Function PresentationOfDocument(Description, Number, Date) Export
	
	Return StrTemplate(
		NStr("vi = '%1 số %2 ngày %3';
			|ru = '%1 № %2 от %3';
			|en = '%1 No. %2 from %3'; fa = '%1 No. %2 from %3';
			|it = '%1 № %2 dal %3';
			|pl = '%1 nr %2 z dnia %3.';
			|tr = '%3 itibaren %1 № %2'"),
		Description,
		ObjectsPrefixesClientServer.NumberForPrinting(Number, False, True),
		Format(Date, "DLF=D"));
	
EndFunction

// Sets the display property of the warning when Editing the form element.
//
Procedure WarningOnEditRepresentation(Item, Show) Export
	
	If Show Then
		Item.WarningOnEditRepresentation = WarningOnEditRepresentation.Show;
	Else
		Item.WarningOnEditRepresentation = WarningOnEditRepresentation.DontShow;
	EndIf;
	
EndProcedure

// Returns the parameters of the mechanism, stored in the requisite shape Kasdanians.
// 
// Parameters:
// 	Form - ClientApplicationForm - Form
// 	MechanismName - String - Name of the mechanism that caches data
//
// Returns:
// 	Arbitrary - 
Function GetEngineDataFromFormCache(Form, MechanismName) Export
	
	If CommonClientServer.HasAttributeOrObjectProperty(Form, "MechanismDataCache") 
		And Form.MechanismDataCache.Property(MechanismName) Then
		Return Form.MechanismDataCache[MechanismName];
	EndIf;
	
	Return Undefined;
	
EndFunction

// Updates the formatted string for working with documents based on the document form
//
// Parameters:
//  Form - ClientApplicationForm - the form must contain Attributes:
// 		* TextDocumentsBasedOn - FormattedString - props must be placed in eliminate with the name of Textdocumentgenerator 
// 		* TextsFieldsDocumentsBasedOn - ValueList of FormattedString - formatted strings of documents generated by configuration mechanisms that are entered based on 
// 
Procedure UpdateTextDocumentsBasedOn(Form) Export
	
	Indent =  New FormattedString("  ");
	TextsDocumentsBasedOn  = New Array;
	
	Counter = 1;
	
	For Each ArrRow In Form.TextsFieldsDocumentsBasedOn Do
		
		If Not IsBlankString(String(ArrRow.Value)) Then
			If Counter > 1 Then
				TextsDocumentsBasedOn.Add(Indent);
			EndIf;				
			TextsDocumentsBasedOn.Add(ArrRow.Value);
			Counter = Counter + 1;
		EndIf;
		
	EndDo;
	
	If TextsDocumentsBasedOn.Count() > 0 Then
		Form.Items.TextDocumentsBasedOn.Visible = True;
		Form.TextDocumentsBasedOn = New FormattedString(TextsDocumentsBasedOn);
	Else
		Form.Items.TextDocumentsBasedOn.Visible = False;
	EndIf;
	
EndProcedure

// The procedure sets the visibility of form elements by an array of names.
//
// Parameters:
//	Items - FormAllItems - Collection of form elements
//	ArrayOfAllProps - Array - Array of names of details to set visibility for
//	ArrayOfVisibleProps - Array - Array of names of details that should be visible on the form.
//
Procedure SetVisibilityOfElementsByArray(Items, Val ArrayOfAllProps, Val ArrayOfVisibleProps) Export
	
	If TypeOf(ArrayOfVisibleProps) <> Type("Array") Then
		ArrayOfVisibleProps = New Array;
	EndIf;
	
	For Each ArrayElement In ArrayOfAllProps Do
		
		AttributeName = StrReplace(ArrayElement, ".", "");
		
		// If the props are not in the array of visible props, remove the visibility of the form element.
		VisibilityOfProps = (ArrayOfVisibleProps.Find(ArrayElement) <> Undefined);
		If Items.Find(AttributeName) <> Undefined
		 And Items[AttributeName].Visible <> VisibilityOfProps Then
			Items[AttributeName].Visible = VisibilityOfProps;
		EndIf;
		
	EndDo;
	
EndProcedure

// Generates parameters for selecting elements based on the parameters specified for the form element.
// Used for selection in selection forms with the same selection parameters as when selecting.
//
// Parameters:
//  FormItem - FormField - A form element that specifies the selection parameters.
//  Form - ClientApplicationForm - The form on which the element is located. Used for getting parameters.
// 
// Returns:
//  Structure - selection parameters:
//  	* CloseOnChoice - Boolean -
//  	* MultipleChoice - Boolean -
//
Function PickingParameters(FormItem, Form) Export

	PickingParameters = New Structure;
	PickingParameters.Insert("CloseOnChoice", False);
	PickingParameters.Insert("MultipleChoice", True);
	
	AddSelectionParametersToSelectionParameters(
		FormItem.ChoiceParameters, PickingParameters);
		
	ChoiceParameterLinks = New Structure;
	AddSelectionParametersToSelectionParametersLink(
		FormItem.ChoiceParameterLinks, Form, ChoiceParameterLinks);
	
	For Each ChoiceParameter In ChoiceParameterLinks Do
		If ChoiceParameter.Key = "Filter" And PickingParameters.Property(ChoiceParameter.Key) Then
			For Each FilterElement In ChoiceParameter.Value Do
				PickingParameters.Filter.Insert(FilterElement.Key, FilterElement.Value);
			EndDo;
		Else
			PickingParameters.Insert(ChoiceParameter.Key, ChoiceParameter.Value);
		EndIf;
	EndDo;
		
	Return PickingParameters;

EndFunction

// Generates parameters for selecting an element based on the parameters specified for the form element.
//
// Parameters:
//  FormItem - FormField - A form element that specifies the selection parameters.
//  Form - ClientApplicationForm - The form on which the element is located. Used for getting parameters.
// 
// Returns:
//  Structure - selection parameters:
//  	* CloseOnChoice - Boolean -
//  	* MultipleChoice - Boolean -
//
Function ChoiceParameters(FormItem, Form) Export

	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("CloseOnChoice", True);
	ChoiceParameters.Insert("MultipleChoice", False);
	
	AddSelectionParametersToSelectionParameters(
		FormItem.ChoiceParameters, ChoiceParameters);
		
	ChoiceParameterLinks = New Structure;
	AddSelectionParametersToSelectionParametersLink(
		FormItem.ChoiceParameterLinks, Form, ChoiceParameterLinks);
	
	For Each ChoiceParameter In ChoiceParameterLinks Do
		If ChoiceParameter.Key = "Filter" And ChoiceParameters.Property(ChoiceParameter.Key) Then
			For Each FilterElement In ChoiceParameter.Value Do
				ChoiceParameters.Filter.Insert(FilterElement.Key, FilterElement.Value);
			EndDo;
		Else
			ChoiceParameters.Insert(ChoiceParameter.Key, ChoiceParameter.Value);
		EndIf;
	EndDo;
		
	Return ChoiceParameters;

EndFunction

// Complements the selection parameters.
// 
// Parameters:
//  ChoiceParameters - FixedArray of ChoiceParameter - the selection parameters.
//  PickingParameters - Structure - Selection parameters that need to be supplemented.
Procedure AddSelectionParametersToSelectionParameters(ChoiceParameters, PickingParameters) Export

	SubParameters = New Map;
	
	For Each CollectionItem In ChoiceParameters Do
		ParameterName = StrSplit(CollectionItem.Name, ".");
		If ParameterName.Count() > 1 Then
			NestedParameter = SubParameters.Get(ParameterName[0]);
			If NestedParameter = Undefined Then
				NestedParameter = New Structure;
			EndIf; 
			NestedParameter.Insert(ParameterName[1], CollectionItem.Value);
			SubParameters.Insert(ParameterName[0], NestedParameter);
		Else
			PickingParameters.Insert(ParameterName[0], CollectionItem.Value);
		EndIf; 
	EndDo; 
	
	For Each NestedParameter In SubParameters Do
		PickingParameters.Insert(NestedParameter.Key, NestedParameter.Value);
	EndDo; 
	
EndProcedure

// Complements the selection parameters.
// 
// Parameters:
//  ChoiceParameterLinks - FixedArray of ChoiceParameterLink - Connections of the selection parameters.
//  Form - ClientApplicationForm - shape.
//  PickingParameters - Structure - Selection parameters that need to be supplemented.
//
Procedure AddSelectionParametersToSelectionParametersLink(ChoiceParameterLinks, Form, PickingParameters) Export

	SubParameters = New Map;
	
	For Each CollectionItem In ChoiceParameterLinks Do
		ParameterValue = ValueOfLinkParameter(CollectionItem, Form);
		ParameterName = StrSplit(CollectionItem.Name, ".");
		If ParameterName.Count() > 1 Then
			NestedParameter = SubParameters.Get(ParameterName[0]);
			If NestedParameter = Undefined Then
				NestedParameter = New Structure;
			EndIf; 
			NestedParameter.Insert(ParameterName[1], ParameterValue);
			SubParameters.Insert(ParameterName[0], NestedParameter);
		Else
			PickingParameters.Insert(ParameterName[0], ParameterValue);
		EndIf; 
	EndDo; 
	
	For Each NestedParameter In SubParameters Do
		PickingParameters.Insert(NestedParameter.Key, NestedParameter.Value);
	EndDo; 
	
EndProcedure

// Calculates the value of the communication parameter.
// 
// Parameters:
//  ChoiceParameterLink - ChoiceParameterLink - Connection of the selection parameter.
//  Form - ClientApplicationForm - shape.
// 
// Returns:
//  Arbitrary -
Function ValueOfLinkParameter(ChoiceParameterLink, Form) Export
	
	ParameterValue = StrSplit(ChoiceParameterLink.DataPath, ".");
	If ParameterValue.Count() = 1 Then
		ParameterValue = Form[ParameterValue[0]];
	ElsIf ParameterValue.Count() = 2 Then
		ParameterValue = Form[ParameterValue[0]][ParameterValue[1]];
	ElsIf ParameterValue.Count() = 3 Then
		ParameterValue = Form[ParameterValue[0]][ParameterValue[1]][ParameterValue[2]];
	ElsIf ParameterValue.Count() = 4 Then
		ParameterValue = Form[ParameterValue[0]][ParameterValue[1]][ParameterValue[2]][ParameterValue[3]];
	ElsIf ParameterValue.Count() = 5 Then
		ParameterValue = Form[ParameterValue[0]][ParameterValue[1]][ParameterValue[2]][ParameterValue[3]][ParameterValue[4]];
	Else
		ParameterValue = Undefined;
	EndIf;
	
	Return ParameterValue;
	
EndFunction

// Forms the path to the current row element of the Form table for issuing messages in the Form.
// To share with the procedure,
// inform the user (to Transfer to the "Field" parameter). 
//
// Parameters:
//  NameOfFormTableElement - String - The name of the table element to which the row belongs.
//  ColumnName - String - name of the prop.
//
// Returns:
//  String - the path to the table cell.
//
Function PathToElementOfCurrentRowOfFormTable(NameOfFormTableElement, ColumnName) Export
	Return StrTemplate(
		"Items.%1.CurrentData.%2",
		NameOfFormTableElement,
		ColumnName)
EndFunction

#EndRegion

#Region FunctionsToSupportFormationOfPrintedForms

// Returns the title of the document in the form in which it is formed by the platform for presenting a link to the document.
//
// Parameters:
//  Header - Structure -  Structure Keys:
//          * Number - String, Number - document number
//          * Date  - Date - Document date
//          * NumberOfDocumentBeingCorrected - String, Number - number of the document to be corrected
//          * DateOfDocumentBeingCorrected - Date - date of the document to be corrected 
//  DocumentName_1 - String - the name of the document (for example, a synonym for the metadata object).
//  RemoveOnlyLeadingZerosFromObjectNumber - Boolean - Flag for deleting leading zeros
//  
// Returns:
//  String - document title
//
Function GenerateDocumentTitle(Header, Val DocumentName_1 = "", RemoveOnlyLeadingZerosFromObjectNumber = False) Export
	
	DocumentData = New Structure("Number, Date, Presentation, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
	FillPropertyValues(DocumentData, Header);
	CorrectiveDocument = ValueIsFilled(DocumentData.NumberOfDocumentBeingCorrected) 
								And ValueIsFilled(DocumentData.DateOfDocumentBeingCorrected);
	
	// If the name of the document is not transmitted, we will get the name according to the presentation of the document
	If IsBlankString(DocumentName_1) And ValueIsFilled(DocumentData.Presentation) Then
		DocumentName_1 = PresentationOfObjectFromReferencePresentation(DocumentData);
	EndIf;

	If RemoveOnlyLeadingZerosFromObjectNumber Then
		NumberForPrinting = ObjectsPrefixesClientServer.DeleteLeadingZerosFromObjectNumber(DocumentData.Number);
		If CorrectiveDocument Then
			NumberOfDocumentToBeCorrectedForPrinting = ObjectsPrefixesClientServer.DeleteLeadingZerosFromObjectNumber(
				DocumentData.NumberOfDocumentBeingCorrected);
		EndIf;
	Else 
		// In addition to the leading zeros, the prefix of the organization and the prefix of the information base will also be deleted.
		NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(DocumentData.Number);
		If CorrectiveDocument Then
			NumberOfDocumentToBeCorrectedForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(
				DocumentData.NumberOfDocumentBeingCorrected);
		EndIf;
	EndIf;
	
	If CorrectiveDocument Then
		DocumentTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 số %2 ngày %3 (chỉnh sửa số %4 ngày %5)';
				|ru = '%1 № %2 от %3 (исправление № %4 от %5)';
				|en = '%1 No. %2 dated %3 (correction No. %4 dated %5)'; fa = '%1 No. %2 dated %3 (correction No. %4 dated %5)';
				|it = '%1 № %2 del %3 (correzione № %4 del %5)';
				|pl = '%1 nr %2 z dnia %3 (korekta nr %4 z dnia %5)';
				|tr = '%1 № %2 itibaren %3 (düzeltme № %4 itibaren %5)'", CommonClientServer.DefaultLanguageCode()),
			DocumentName_1,
			NumberOfDocumentToBeCorrectedForPrinting,
			Format(DocumentData.DateOfDocumentBeingCorrected, "DLF=DD"),
			NumberForPrinting,
			Format(DocumentData.Date, "DLF=DD"));
	Else
		DocumentTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 số %2 ngày %3';
				|ru = '%1 № %2 от %3';
				|en = '%1 #%2, %3'; fa = '%1 #%2, %3';
				|it = '%1 № %2 dal %3';
				|pl = '%1 nr %2 z dnia %3.';
				|tr = '%3 itibaren %1 № %2'", CommonClientServer.DefaultLanguageCode()),
			DocumentName_1, NumberForPrinting, Format(DocumentData.Date, "DLF=DD"));
	EndIf;
	
	Return DocumentTitle;
	
EndFunction

// Example function: representation of the object "customer Order 00001 from 22.01.2014 0: 00:00", the function returns "customer Order".
//
// Parameters:
//  DocumentData - Structure 
//		* Representation - the String representation of the reference
//		* Number - Line - document number
// Returns:
//   String - representation of objects.
//
Function PresentationOfObjectFromReferencePresentation(Val DocumentData) Export 
	
	NumberPosition = StrFind(DocumentData.Presentation, DocumentData.Number);
	
	If NumberPosition > 0 Then
        DocumentName_1 = TrimAll(Left(DocumentData.Presentation, NumberPosition - 1));
	Else
		DocumentName_1 = "";
	EndIf;
	
	Return DocumentName_1;

EndFunction

// Adds a new parameter to the selection parameters of the passed form element, while preserving the previously added parameters.
//
// Parameters:
//  Item - FormField - a form element that has the "selection Parameter" property"
//  ParameterName - String - the name of the parameter as it is defined by the property "of Paravyoma - Name" without specifying the word "Selection."
//  ParameterValue - Arbitrary - values of the selection parameter. For a single selection, the value itself is passed, and for
//                                     a multiple selection, an array of values is passed.
//
Procedure AddSelectionParameter(Item, ParameterName, ParameterValue) Export
	If TypeOf(ParameterValue) = Type("Array") Then
		ChoiceParameterValue = New FixedArray(ParameterValue);
	ElsIf TypeOf(ParameterValue) = Type("FixedArray") Then
		ChoiceParameterValue = ParameterValue;
	Else
		ChoiceParameterValue = ParameterValue;
	EndIf;
	
	If StrFind(ParameterName, "Filter.") Then
		NameOfSelectionParameter = ParameterName;
	Else
		NameOfSelectionParameter = "Filter." + ParameterName;
	EndIf;
	
	If TypeOf(Item) = Type("DataCompositionSchemaDataSetField") Then
		ChoiceParameters = Item.EditParameters.FindParameterValue(New DataCompositionParameter("ChoiceParameters"));
		ChoiceParameters.Use = True;
		
		ParameterValue = ChoiceParameters.Value; // List of values -
		SelectionParameterToAdd = ParameterValue.Add();
		SelectionParameterToAdd.Name = NameOfSelectionParameter;
		SelectionParameterToAdd.Value = ChoiceParameterValue;
	Else 
		InitialSelectionParameters = Item.ChoiceParameters;
		
		SelectionParameterToAdd = New ChoiceParameter(NameOfSelectionParameter, ChoiceParameterValue);
		
		ChoiceParametersArray = New Array(InitialSelectionParameters);
		ChoiceParametersArray.Add(SelectionParameterToAdd);
		NewSelectionOptions = New FixedArray(ChoiceParametersArray);
		
		Item.ChoiceParameters = NewSelectionOptions;
	EndIf;
EndProcedure

// The event occurs when an incoming document view is received.
// 
// Parameters:
//  Data - Structure - contains the Attributes of the document that are used to form the Presentation:
//  	* Number - String - document number in the information database
//  	* Date - Date - date of the document in the information database
//  	* ExternalDocumentName - String - name of the counterparty's document
//  	* IncomingDocumentNumber - String - counterparty's document number
//  	* IncomingDocumentDate - Date - date of the counterparty's document
//  Presentation - String - new document view if standard processing = Lies
//  StandardProcessing - Boolean - if a Lie is returned, then the presentation of the document has been changed.
//  DocumentNameOrID - String -
//  			- CatalogRef.MetadataObjectIDs -
//  			- CatalogRef.ExtensionObjectIDs - The name or ID of the document in the metadata.
//
Procedure ProcessingReceivingPresentationOfIncomingDocument(Data, Presentation, StandardProcessing, DocumentNameOrID) Export
	
	ExternalDocumentName = ?(ValueIsFilled(Data.ExternalDocumentName),
								Data.ExternalDocumentName, "---");
	IncomingDocumentNumber = ?(ValueIsFilled(Data.IncomingDocumentNumber),
								Data.IncomingDocumentNumber, "---");
	IncomingDocumentDate = ?(ValueIsFilled(Data.IncomingDocumentDate),
								Format(Data.IncomingDocumentDate, "DLF=D;"), "---");
	#If Client Then
		DocumentPresentationMethod = TMCommonUseClientCached.ConstantValue(
										"PresentationOfIncomingDocuments");
	#Else
		DocumentPresentationMethod = TMCommonUseCached.ConstantValue(
										"PresentationOfIncomingDocuments");
	#EndIf
	If DocumentPresentationMethod = PredefinedValue("Enum.IncomingDocumentPresentationMethods.Full") Then
		StandardProcessing = False;
		Template = NStr("vi = '%1 %2 ngày %3';
						|ru = '%1 %2 от %3';
						|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
						|it = '%1 %2 del %3';
						|pl = '%1 %2 z dnia %3';
						|tr = '%3 tarihli %1 %2'");
		RegularlyPresentation = StandardDocumentPresentation(
									DocumentNameOrID, Data.Number, Data.Date, Presentation);
		IncomingPresentation = StrTemplate(
							Template, ExternalDocumentName, IncomingDocumentNumber, IncomingDocumentDate);
		Template = NStr("vi = '%1 (đầu vào %2)';
						|ru = '%1 (вх. %2)';
						|en = '%1 (inc. %2)'; fa = '%1 (inc. %2)';
						|it = '%1 (in entrata %2)';
						|pl = '%1 (wch. %2)';
						|tr = '%1 (gelen %2)'");
		Presentation = StrTemplate(Template, RegularlyPresentation, IncomingPresentation);
	ElsIf DocumentPresentationMethod = PredefinedValue("Enum.IncomingDocumentPresentationMethods.External") Then
		StandardProcessing = False;
		If ValueIsFilled(Data.ExternalDocumentName)
			And ValueIsFilled(Data.IncomingDocumentNumber)
			And ValueIsFilled(Data.IncomingDocumentDate) Then
			Template = NStr("vi = 'đầu vào %1 %2 ngày %3';
							|ru = 'вх. %1 %2 от %3';
							|en = 'inc. %1 %2 dated %3'; fa = 'inc. %1 %2 dated %3';
							|it = 'in entrata %1 %2 del %3';
							|pl = 'wch. %1 %2 z dn. %3';
							|tr = 'gelen. %1 %2 itibaren %3'");
			Presentation = StrTemplate(
							Template, ExternalDocumentName, IncomingDocumentNumber, IncomingDocumentDate);
		ElsIf ValueIsFilled(Data.ExternalDocumentName) Then
			Template = NStr("vi = 'đầu vào %1 %2 ngày %3, nội bộ %4 ngày %5';
							|ru = 'вх. %1 %2 от %3, вн. %4 от %5';
							|en = 'incoming %1 %2 dated %3, # %4 dated %5'; fa = 'incoming %1 %2 dated %3, # %4 dated %5';
							|it = 'in entrata %1 %2 del %3, interno %4 del %5';
							|pl = 'wch. %1 %2 z dn. %3, wewn. %4 z dn. %5';
							|tr = 'gelen. %1 %2 itibaren %3, numara. %4 %5 itibaren'");
			Presentation = StrTemplate(Template, ExternalDocumentName, IncomingDocumentNumber,
							IncomingDocumentDate, Data.Number, Data.Date);
		Else
			RegularlyPresentation = StandardDocumentPresentation(
										DocumentNameOrID, Data.Number, Data.Date, Presentation);
			Template = NStr("vi = 'đầu vào %1 %2 ngày %3, nội bộ %4';
							|ru = 'вх. %1 %2 от %3, вн. %4';
							|en = 'incoming %1 %2 dated %3, # %4'; fa = 'incoming %1 %2 dated %3, # %4';
							|it = 'in entrata %1 %2 del %3, interno %4';
							|pl = 'wch. %1 %2 z dn. %3, wewn. %4';
							|tr = 'gelen. %1 %2 itibaren %3, numara. %4'");
			Presentation = StrTemplate(Template, ExternalDocumentName, IncomingDocumentNumber,
							IncomingDocumentDate, RegularlyPresentation);
		EndIf;
	EndIf;
	
EndProcedure

// Generates a standard representation of the document in the user's current language.
//
// Parameters:
//  DocumentNameOrID - String
//                               - CatalogRef.MetadataObjectIDs
//                               - CatalogRef.ExtensionObjectIDs 
//  Number - String - document number.
//  Date - Date - Document date
//  Presentation - String - (optional) The previously formed view, if not filled in, then the view is formed
// Returns:
//   String - presentation of the document in the user's current language.
//
Function StandardDocumentPresentation(DocumentNameOrID, Number, Date, Presentation = Undefined) Export
	
	If ValueIsFilled(Presentation) Then
		Return Presentation;
	Else
		Template = NStr("vi = '%1 %2 ngày %3';
						|ru = '%1 %2 от %3';
						|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
						|it = '%1 %2 del %3';
						|pl = '%1 %2 z dnia %3';
						|tr = '%3 tarihli %1 %2'");
		Return StrTemplate(Template, DocumentSynonym(DocumentNameOrID), Number, Date);
	EndIf;
	
EndFunction

#EndRegion

#Region SelectingPeriodFromList

// Returns the beginning of the period by its type.
// Parameters:
// 	PeriodType - EnumRef.AvailableReportPeriods -
// 	PeriodDate_ - Date - 
// Returns:
// 	Date - 
Function BeginningOfReportPeriod(PeriodType, PeriodDate_) Export
	
	BeginOfPeriod = PeriodDate_;
	
	If PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		BeginOfPeriod = BegOfYear(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		If Month(PeriodDate_) > 6 Then
			BeginOfPeriod = Date(Year(PeriodDate_), 7, 1);
		Else
			BeginOfPeriod = Date(Year(PeriodDate_), 1, 1);
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		BeginOfPeriod = BegOfQuarter(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		BeginOfPeriod = BegOfMonth(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		If Day(PeriodDate_) <= 10 Then
			BeginOfPeriod = Date(Year(PeriodDate_), Month(PeriodDate_), 1);
		ElsIf Day(PeriodDate_) > 10 And Day(PeriodDate_) <= 20 Then
			BeginOfPeriod = Date(Year(PeriodDate_), Month(PeriodDate_), 11);
		Else
			BeginOfPeriod = Date(Year(PeriodDate_), Month(PeriodDate_), 21);
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		BeginOfPeriod = BegOfWeek(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		BeginOfPeriod = BegOfDay(PeriodDate_);
		
	EndIf;
		
	Return BeginOfPeriod;
	
EndFunction
 
// Returns the end of the period by its type.
//
// Parameters:
// 	PeriodType - EnumRef.AvailableReportPeriods -
// 	PeriodDate_ - Date - 
// Returns:
// 	Date - 
Function EndOfReportPeriod(PeriodType, PeriodDate_) Export
	
	EndOfPeriod = PeriodDate_;
	
	If PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		EndOfPeriod = EndOfYear(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		If Month(PeriodDate_) > 6 Then
			EndOfPeriod = EndOfYear(PeriodDate_);
		Else
			EndOfPeriod = EndOfDay(Date(Year(PeriodDate_), 6, 30));
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		EndOfPeriod = EndOfQuarter(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		EndOfPeriod = EndOfMonth(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		If Day(PeriodDate_) <= 10 Then
			EndOfPeriod = EndOfDay(Date(Year(PeriodDate_), Month(PeriodDate_), 10));
		ElsIf Day(PeriodDate_) > 10 And Day(PeriodDate_) <= 20 Then
			EndOfPeriod = EndOfDay(Date(Year(PeriodDate_), Month(PeriodDate_), 20));
		Else
			EndOfPeriod = EndOfMonth(PeriodDate_);
		EndIf;
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		EndOfPeriod = EndOfWeek(PeriodDate_);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		EndOfPeriod = EndOfDay(PeriodDate_);
		
	EndIf;
		
	Return EndOfPeriod;
	
EndFunction

// Returns a list of available values of the period in his mind.
//
// Parameters:
// 	BeginOfPeriod - Date -
// 	PeriodType - EnumRef.AvailableReportPeriods
// Returns:
// 	ValueList - List of values -
Function AvailablePeriodValuesByPeriodType(Val BeginOfPeriod, Val PeriodType) Export
	
	PeriodsList = New ValueList;
	If BeginOfPeriod = '00010101' Then
		Return New ValueList;
	Else
		StartOfPeriodValue = BeginOfPeriod;
	EndIf;
	
	If PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		CurrentYear = Year(StartOfPeriodValue);
		PeriodsList.Add(Date(CurrentYear - 7, 1, 1), NStr("vi = 'Năm trước';
															|ru = 'Предыдущие годы';
															|en = 'Previous years'; fa = 'Previous years';
															|it = 'Anni precedenti';
															|pl = 'Poprzednie lata';
															|tr = 'Önceki yıllar'"));
		For Cnt = CurrentYear - 3 To CurrentYear + 3 Do
			PeriodsList.Add(Date(Cnt, 1, 1), Format(Cnt, "NG=0"));
		EndDo;
		PeriodsList.Add(Date(CurrentYear + 7, 1, 1), NStr("vi = 'Năm tiếp theo';
															|ru = 'Последующие годы';
															|en = 'Subsequent years'; fa = 'Subsequent years';
															|it = 'Anni successivi';
															|pl = 'Następujące lata';
															|tr = 'Gelecek yıllar'"));
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		CurrentYear = Year(StartOfPeriodValue);
		PeriodsList.Add(Date(CurrentYear - 2, 1, 1), Format(CurrentYear - 2, "NG=0") + "...");
		For Cnt = CurrentYear - 1 To CurrentYear + 1 Do
			PeriodsList.Add(Date(Cnt, 1, 1), NStr("vi = '6 tháng đầu năm';
													|ru = 'I полугодие';
													|en = 'Half-year I'; fa = 'نیم‌سال اول';
													|it = 'I semestre';
													|pl = 'I półrocze';
													|tr = 'I. yarıyıl'")  + " " + Format(Cnt, "NG=0"));
			PeriodsList.Add(Date(Cnt, 7, 1), NStr("vi = '6 tháng cuối năm';
													|ru = 'II полугодие';
													|en = 'Half-year II'; fa = 'نیم‌سال دوم';
													|it = 'II semestre';
													|pl = 'II półrocze';
													|tr = 'II. yarıyıl'") + " " + Format(Cnt, "NG=0"));
		EndDo;
		PeriodsList.Add(Date(CurrentYear + 2, 1, 1), Format(CurrentYear + 2, "NG=0") + "...");
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		CurrentYear = Year(StartOfPeriodValue);
		PeriodsList.Add(Date(CurrentYear - 2, 1, 1), Format(CurrentYear - 2, "NG=0") + "...");
		For Cnt = CurrentYear - 1 To CurrentYear Do
			PeriodsList.Add(Date(Cnt, 1, 1), NStr("vi = 'Quý I';
													|ru = 'I квартал';
													|en = 'Quarter I'; fa = 'فصل اول';
													|it = 'I trimestre';
													|pl = 'I kwartał';
													|tr = 'I. çeyrek'")   + " " + Format(Cnt, "NG=0"));
			PeriodsList.Add(Date(Cnt, 4, 1), NStr("vi = 'Quý II';
													|ru = 'II квартал';
													|en = 'Quarter II'; fa = 'فصل دوم';
													|it = 'II trimestre';
													|pl = 'II kwartał';
													|tr = 'II. çeyrek'")  + " " + Format(Cnt, "NG=0"));
			PeriodsList.Add(Date(Cnt, 7, 1), NStr("vi = 'Quý III';
													|ru = 'III квартал';
													|en = 'Quarter III'; fa = 'فصل سوم';
													|it = 'III trimestre';
													|pl = 'III kwartał';
													|tr = 'III. çeyrek'") + " " + Format(Cnt, "NG=0"));
			PeriodsList.Add(Date(Cnt, 10, 1),NStr("vi = 'Quý IV';
													|ru = 'IV квартал';
													|en = 'Quarter IV'; fa = 'فصل چهارم';
													|it = 'IV trimestre';
													|pl = 'IV kwartał';
													|tr = 'IV. çeyrek'")  + " " + Format(Cnt, "NG=0"));
		EndDo;
		PeriodsList.Add(Date(CurrentYear + 1, 1, 1), Format(CurrentYear + 1, "NG=0") + "...");
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		CurrentYear = Year(StartOfPeriodValue);
		PeriodsList.Add(Date(CurrentYear - 1, 1, 1), Format(CurrentYear - 1, "NG=0") + "...");
		For Cnt = 1 To 12 Do
			PeriodsList.Add(Date(CurrentYear, Cnt, 1), Format(Date(CurrentYear, Cnt, 1), NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
																								|ru = 'ДФ=''MMMM yyyy''';
																								|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																								|it = 'ДФ=''ММММ гггг''';
																								|pl = 'DF=''MMMM yyyy''';
																								|tr = 'ДФ=''ММММ гггг'''")));
		EndDo;
		PeriodsList.Add(Date(CurrentYear + 1, 1, 1), Format(CurrentYear + 1, "NG=0") + "...");

	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		CurrentYear   = Year(StartOfPeriodValue);
		CurrentMonth = Month(StartOfPeriodValue);
		
		CountMonth = ?(CurrentMonth - 4 < 1, 12 + CurrentMonth - 4, CurrentMonth - 4);
		CountYear   = ?(CurrentMonth - 4 < 1, CurrentYear - 1       , CurrentYear);
		Cnt = 6;
		
		Period = Date(?(CountMonth <> 1, CountYear, CountYear - 1), ?(CountMonth > 1, CountMonth - 1, 12), 1);
		PeriodsList.Add(Period, Format(Period, NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
													|ru = 'ДФ=''MMMM yyyy''';
													|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
													|it = 'ДФ=''ММММ гггг''';
													|pl = 'DF=''MMMM yyyy''';
													|tr = 'ДФ=''ММММ гггг'''")) + "...");
		While Cnt >0 Do
			PeriodsList.Add(Date(CountYear, CountMonth, 1),  NStr("vi = 'mười ngày.';
																	|ru = 'I дек.';
																	|en = 'Ten-day period 1'; fa = 'Ten-day period 1';
																	|it = '1 dec.';
																	|pl = 'I grud.';
																	|tr = 'I 10 günlük süre.'")   + " " + Lower(Format(Date(CountYear, CountMonth, 1), NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
																																						|ru = 'ДФ=''MMMM yyyy''';
																																						|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																																						|it = 'ДФ=''ММММ гггг''';
																																						|pl = 'DF=''MMMM yyyy''';
																																						|tr = 'ДФ=''ММММ гггг'''"))));
			PeriodsList.Add(Date(CountYear, CountMonth, 11), NStr("vi = 'Hai mươi ngày';
																	|ru = 'II дек.';
																	|en = 'Ten-day period 2'; fa = 'Ten-day period 2';
																	|it = '2 dec.';
																	|pl = 'II grud.';
																	|tr = 'II 10 günlük süre.'")  + " " + Lower(Format(Date(CountYear, CountMonth, 1), NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
																																						|ru = 'ДФ=''MMMM yyyy''';
																																						|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																																						|it = 'ДФ=''ММММ гггг''';
																																						|pl = 'DF=''MMMM yyyy''';
																																						|tr = 'ДФ=''ММММ гггг'''"))));
			PeriodsList.Add(Date(CountYear, CountMonth, 21), NStr("vi = 'Ba mươi ngày';
																	|ru = 'III дек.';
																	|en = 'Ten-day period 3'; fa = 'Ten-day period 3';
																	|it = '3 dec.';
																	|pl = 'III grud.';
																	|tr = 'III 10 günlük süre.'") + " " + Lower(Format(Date(CountYear, CountMonth, 1), NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
																																						|ru = 'ДФ=''MMMM yyyy''';
																																						|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																																						|it = 'ДФ=''ММММ гггг''';
																																						|pl = 'DF=''MMMM yyyy''';
																																						|tr = 'ДФ=''ММММ гггг'''"))));
			CountMonth = CountMonth + 1;
			If CountMonth > 12 Then
				CountYear = CountYear + 1;
				CountMonth = 1;
			EndIf;
			Cnt = Cnt - 1;
		EndDo;
		PeriodsList.Add(Date(CountYear, CountMonth, 1), Format(Date(CountYear, CountMonth, 1), NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
																									|ru = 'ДФ=''MMMM yyyy''';
																									|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																									|it = 'ДФ=''ММММ гггг''';
																									|pl = 'DF=''MMMM yyyy''';
																									|tr = 'ДФ=''ММММ гггг'''")) + "...");
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		BegOfWeek = BegOfWeek(StartOfPeriodValue) - 21 * 86400;
		
		PeriodsList.Add(BegOfWeek - 7 * 86400, NStr("vi = 'Tuần trước';
													|ru = 'Пред. недели';
													|en = 'Previous weeks'; fa = 'Previous weeks';
													|it = 'Settimana precedente';
													|pl = 'Poprz. tygodnie';
													|tr = 'Önceki haftalar'") + " ...");
		For Cnt = 0 To 6 Do
			BeginningOfWeek = BegOfWeek + 7 * Cnt * 86400;  
			NdOfWeek = EndOfWeek(BeginningOfWeek);
			PeriodsList.Add(BeginningOfWeek, Format(BeginningOfWeek, NStr("vi = 'ДФ=''дд.ММ''';
																			|ru = 'ДФ=''dd.MM''';
																			|en = 'DF=''dd.MM'''; fa = 'DF=''dd.MM''';
																			|it = 'ДФ=''дд.ММ''';
																			|pl = 'DF=''dd.MM''';
																			|tr = 'ДФ=''дд.ММ'''")) + " - " + Format(NdOfWeek, NStr("vi = 'ДФ=''дд.ММ''';
																																	|ru = 'ДФ=''dd.MM''';
																																	|en = 'DF=''dd.MM'''; fa = 'DF=''dd.MM''';
																																	|it = 'ДФ=''дд.ММ''';
																																	|pl = 'DF=''dd.MM''';
																																	|tr = 'ДФ=''дд.ММ'''")));
		EndDo;
		PeriodsList.Add(BegOfWeek + 7 * 86400, NStr("vi = 'Tuần tới';
													|ru = 'След. недели';
													|en = 'Next weeks'; fa = 'Next weeks';
													|it = 'Settimana successiva';
													|pl = 'Nast. tygodnie';
													|tr = 'Sonraki haftalar'") + " ...");
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		EndOfWeek   = EndOfWeek(StartOfPeriodValue);
		DayOfWeekDate = BegOfWeek(StartOfPeriodValue);
		
		PeriodsList.Add(DayOfWeekDate - 86400, NStr("vi = 'Tuần trước';
													|ru = 'Предыдущая неделя';
													|en = 'Previous week'; fa = 'Previous week';
													|it = 'Settimana precedente';
													|pl = 'Poprzedni tydzień';
													|tr = 'Önceki hafta'"));
		
		While DayOfWeekDate < EndOfWeek Do
			PeriodsList.Add(DayOfWeekDate, Format(DayOfWeekDate, NStr("vi = 'ДФ=''дд ММММ гггг (ддд)''';
																		|ru = 'ДФ=''dd MMMM yyyy (ddd)''';
																		|en = 'DF=''dd MMMM yyyy (ddd)'''; fa = 'DF=''dd MMMM yyyy (ddd)''';
																		|it = 'ДФ=''дд ММММ гггг (ддд)''';
																		|pl = 'DF=''dd MMMM yyyy (ddd)''';
																		|tr = 'ДФ=''дд ММММ гггг (ддд)'''")));
			DayOfWeekDate = DayOfWeekDate + 86400;
		EndDo;
		
		PeriodsList.Add(EndOfWeek + 1, NStr("vi = 'Tuần sau';
											|ru = 'Следующая неделя';
											|en = 'Next week'; fa = 'هفته بعد';
											|it = 'Settimana successiva';
											|pl = 'Następny tydzień';
											|tr = 'Sonraki hafta'"));
	EndIf;
	
	Return PeriodsList;
	
EndFunction

#EndRegion

#Region WorkingWithDynamicLists

// Defines the selection of a dynamic list depending on whether compatibility mode is available.
//
// Parameters:
//  List - DynamicList - the list for which it is necessary to determine the selection.
//
// Returns:
//   Filter - required selection
//
Function GetDynamicListSelection(List) Export
	
	Return List.SettingsComposer.FixedSettings.Filter;
	
EndFunction

// Defines the grouping fields of the dynamic list, depending on whether compatibility mode is available.
//
// Parameters:
//  List - DynamicList - the list for which it is necessary to determine the grouping.
//
// Returns:
//   DataCompositionGroupFields - required grouping fields.
//
Function GetDynamicListGroupingFields(List) Export
	Var Group, GroupFields;
	
	For Each Item In List.SettingsComposer.Settings.Structure Do
		If TypeOf(Item) = Type("DataCompositionGroup") Then
			Group = Item;
			Break;
		EndIf;
	EndDo;
	
	If Group = Undefined Then
		Group = List.SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
		Group.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	EndIf;
	
	GroupFields = Group.GroupFields;
		
	Return GroupFields;
	
EndFunction

// Defines the conditional appearance of the dynamic list, depending on whether compatibility mode is available.
//
// Parameters:
//  List - DynamicList - the list for which it is necessary to define the conditional execution.
//
// Returns:
//   ConditionalAppearance - required conditional registration.
//
Function GetConditionalAppearanceOfDynamicList(List) Export
	
	Return List.SettingsComposer.FixedSettings.ConditionalAppearance;
	
EndFunction

#EndRegion

#Region OperationsWithDocumentJournals 

// Sets the visibility of the form elements to be displayed for the workplace.
//
// Parameters:
//  Form	 - ClientApplicationForm	 - form with the table economic Operationidocuments
//	NamesOfElementsWithManagedVisibility - String - the names of the form elements, separated by commas
//	WorkplaceKey - String - identifies the workplace.
//
Procedure SetVisibilityOfWorkplaceElements(Form, NamesOfElementsWithManagedVisibility, WorkplaceKey) Export 
	
	InvisibleElements = New Structure(NamesOfElementsWithManagedVisibility);
	
	For Each Page1 In Form.BusinessTransactionsAndDocuments Do
		If Page1.Filter
		 And Page1.PurposeUseKey = WorkplaceKey Then
		 
			VisibleElements = New Structure(Page1.WorkplaceItemNames);
			For Each KeyAndValue In VisibleElements Do
				InvisibleElements.Delete(KeyAndValue.Key);
				FormItem = Form.Items[KeyAndValue.Key]; // FormField - 
				FormItem.Visible = True;
			EndDo;
		EndIf;
	EndDo;
	
	For Each KeyAndValue In InvisibleElements Do
		FormItem = Form.Items[KeyAndValue.Key]; // FormField -
		FormItem.Visible = False;
	EndDo;
			
EndProcedure

#EndRegion

#Region ConvertingDataTypes

// Puts the passed data in an array.
//
// Parameters:
//	Item - Arbitrary
//	IgnoreEmptyValue - Boolean - if True, an empty Element will not be added to the result.
//
// Returns:
//	Array of Arbitrary -
//
Function Array(Item, IgnoreEmptyValue = True) Export
	
	If TypeOf(Item) = Type("Array") Then
		Array = Item;
	ElsIf TypeOf(Item) = Type("ValueList") Then
		Array = Item.UnloadValues();
	ElsIf TypeOf(Item) = Type("FixedArray") Then
		Array = New Array(Item);
	Else
		Array = New Array;
		If Not IgnoreEmptyValue Or ValueIsFilled(Item) Then
			Array.Add(Item);
		EndIf;
	EndIf;
	
	Return Array;
	
EndFunction

// Sorts array values
// 
// Parameters:
//  SourceArray - Array of Arbitrary - The original array
//  Direction - SortDirection - Sorting direction
// 
// Returns:
//  Array of Arbitrary - Array to sort
Function Sorted_Array(SourceArray, Direction = Undefined) Export
	
	If Direction = Undefined Then
		Direction = SortDirection.Asc;
	EndIf;
	
	List = New ValueList;
	List.LoadValues(SourceArray);
	List.SortByValue(Direction);
	
	Return List.UnloadValues();
	
EndFunction

// Converts the passed collection to an array.
//
// Parameters:
//	RawData - Structure, Map - Source collection
//	ConvertKey - Boolean - determines that it is necessary to convert the key or value.
//
// Returns:
//	Array - keys or values of the passed collection.
//
//@skip-warning
Function ConvertMatchOrStructureToArray(RawData, ConvertKey = True) Export
	
	Result = New Array;
	
	For Each KeyAndValue In RawData Do
		Result.Add(?(ConvertKey, KeyAndValue.Key, KeyAndValue.Value));
	EndDo;
	
	Return Result;
	
EndFunction
	
// Converts the supplied array into a structure, or under which the keys will be the elements of the array.
//
// Parameters:
//	RawData - Array - 
//	ConvertToStructure - Boolean - defines what to convert to.
//
// Returns:
//	Structure, Map - 
//
//@skip-warning
Function ConvertArrayToStructureOrMatch(RawData, ConvertToStructure) Export
	
	If ConvertToStructure Then
		Result = New Structure;
	Else
		Result = New Map;
	EndIf;
	
	For Each CurrentItem In RawData Do
		Result.Insert(CurrentItem, CurrentItem);
	EndDo;
	
	Return Result;
	
EndFunction
	
// Returns a string with a maximum length of a certain number of characters.
// If the string is larger , it is truncated and an ellipsis is added to the end.
//
// Parameters:
//  InitialString		 - String 
//  MaxLength	 - Number 
//
// Returns:
//  String 
//
Function PresentationOfStringWithMaximumLengthOf(InitialString, MaxLength) Export
	
	If StrLen(InitialString) <= MaxLength Then
		Return InitialString;
	Else
		Return Left(InitialString, StrLen(InitialString) - 3) + "...";
	EndIf;
	
EndFunction

// Checks whether the string is a non-negative integer	
// Parameters:
//  RowToValidate - String - the string being checked.
//
// Returns:
//  Boolean - True if the string contains only digits.
//
Function ThisStringIsNonNegativeInteger(RowToValidate) Export
	
	StringIsNumber = True;
	RowToValidate = TrimAll(RowToValidate);
	Length = StrLen(RowToValidate);
	
	For CharacterNumber = 1 To Length Do
		Simv = Mid(RowToValidate, CharacterNumber, 1);
		If Find("0123456789", Simv) = 0 And CharCode(Simv)<>160 Then
			StringIsNumber = False;		
		EndIf;		
	EndDo;
		
	Return StringIsNumber;
	
EndFunction

// Adds a value to the array if this value is not already in the array.
//
// Parameters:
//	Array - Array
//	Value - Arbitrary
//
// Returns:
//	Boolean - whether the element was added.
//
Function AddNewValueToArray(Array, Value) Export
	
	If Array.Find(Value) = Undefined Then 
		Array.Add(Value);
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Creates a match whose keys are parts of the passed string.
//
// Parameters:
//	String_Keys - String - arbitrary string
//	Separator  - String - the delimiter parts of the lines.
//
// Returns:
//	Map - parts of the passed string, the values are True.
//
//@skip-warning
Function ConvertKeyStringToMatch(String_Keys, Separator = ",") Export
	
	Result = New Map;
	Array = StringFunctionsClientServer.SplitStringIntoSubstringsArray(String_Keys, Separator, True, True);
	
	For Each Item In Array Do
		Result.Insert(Item, True);
	EndDo;
	
	Return Result;
	
EndFunction

// Creates a structure whose keys are match keys.
//
// Parameters:
//	Map - Map
//
// Returns:
//	Structure - 
//
//@skip-warning
Function ConvertCorrespondenceToStructure(Map) Export
	
	Result = New Structure;
	
	If Not TypeOf(Map) = Type("Map") Then
		Return Result
	EndIf; 
	
	For Each Item In Map Do
		Result.Insert(Item.Key, Item.Value);
	EndDo;
	
	Return Result;
	
EndFunction

// Creates a line whose keys are the keys of the structure.
//
// Parameters:
//	Structure - Structure
//
// Returns:
//	Map - 
//
//@skip-warning
Function ConvertStructureToConform(Structure) Export
	
	Result = New Map;
	
	If Not TypeOf(Structure) = Type("Structure") Then
		Return Result
	EndIf; 

	For Each Item In Structure Do
		Result.Insert(Item.Key, Item.Value);
	EndDo;
	
	Return Result;
	
EndFunction

// Creates an array whose values are elements that are present in only one of the arrays.
//
// Parameters:
//	Array1 - Array
//	Array2 - Array
//
// Returns:
//	Array - (elements of Arrays 1 missing in Arrays 2) + (elements of Arrays 2 missing in Arrays 1).
//
//@skip-warning
Function ArrayDifferences(Array1, Array2) Export
	
	Differences1 = New Array;
	
	For Each CurrentItem In Array1 Do
		If Array2.Find(CurrentItem) = Undefined Then
			AddNewValueToArray(Differences1, CurrentItem);
		EndIf;
	EndDo;
	
	For Each CurrentItem In Array2 Do
		If Array1.Find(CurrentItem) = Undefined Then
			AddNewValueToArray(Differences1, CurrentItem);
		EndIf;
	EndDo;
	
	Return Differences1;
	
EndFunction

// Creates an array whose values are the elements present in each of the arrays.
//
// Parameters:
//	Array1 - Array
//	Array2 - Array
//
// Returns:
//	Array - (the elements of Array 1 present in Array 2).
//
//@skip-warning
Function IntersectionOfArrays(Array1, Array2) Export
	
	Intersection = New Array;
	
	For Each CurrentItem In Array1 Do
		If Array2.Find(CurrentItem) <> Undefined Then
			AddNewValueToArray(Intersection, CurrentItem);
		EndIf;
	EndDo;
	
	Return Intersection;
	
EndFunction

// Checks that there are no elements with filled values in the passed structure.
//
// Parameters:
//	Data - Structure
//
// Returns:
//	Boolean - True if there is not a single filled value in the structure.
//
Function StructureValuesAreNotFilled(Data) Export
	
	BlankValues = True;
	
	For Each KeyAndValue In Data Do
		
		If (TypeOf(KeyAndValue.Value) = Type("Boolean") And KeyAndValue.Value)
		 Or (TypeOf(KeyAndValue.Value) <> Type("Boolean") And ValueIsFilled(KeyAndValue.Value)) Then
			BlankValues = False;
			Break;
		EndIf;
		
	EndDo;
	
	Return BlankValues;
	
EndFunction

// Sorts the elements of the array.
//
// Parameters:
//	Array - Array - the array to be sorted.
//
Procedure SortArray(Array) Export
	
	List = New ValueList;
	
	List.LoadValues(Array);
	List.SortByValue();
	
	Array = List.UnloadValues();
	
EndProcedure

// The procedure checks duplicates of values in the array
//
// Parameters:
//  Array				  - Array			 - array being checked
//  Cancel				  - Boolean			 - failure to continue the operation.
//  ArrayPresentation  - String			 - representation of the data type for users.
//  ValuesPresentation - String			 - specifies whether to display the line number in the error message.
//  ExcludeEmptyOnes       - Boolean			 - specifies whether to exclude empty values from the array before checking duplicates.
//
Procedure CheckForDuplicatesOfArrayValues(Array, Cancel, ArrayPresentation = "", ValuesPresentation = "", ExcludeEmptyOnes = False) Export
	
	ArrayCopy = New Array;
	For Each Value In Array Do
		If Not ExcludeEmptyOnes Or ValueIsFilled(Value) Then
			ArrayCopy.Add(Value);
		EndIf;
	EndDo;
	
	TMCommonUseClientServer.SortArray(ArrayCopy);
	
	MessageTemplate = NStr("vi = 'Trong danh sách ""%ArrayPresentation%"" giá trị lặp lại ""%RepeatableValue%"" tại trường %ValuesPresentation%.';
							|ru = 'В списке ""%ArrayPresentation%"" повторяется значение ""%RepeatableValue%"" в поле %ValuesPresentation%.';
							|en = 'In the ""%ArrayPresentation%"" list, the ""%RepeatableValue%"" value is repeated in field %%ValuesPresentation%%.'; fa = 'In the ""%ArrayPresentation%"" list, the ""%RepeatableValue%"" value is repeated in field %%ValuesPresentation%%.';
							|it = 'Nell''elenco ""%ArrayPresentation%"" si ripete il valore ""%RepeatableValue%"" nel campo %ValuesPresentation%.';
							|pl = 'Na liście ""%ArrayPresentation%"" powtarza się wartość ""%RepeatableValue%"" w polu %ValuesPresentation%.';
							|tr = '""%ArrayPresentation%"" listesinde, %ValuesPresentation% alanındaki ""%RepeatableValue%"" değeri tekrarlanıyor.'");
	MessageTemplate = StrReplace(MessageTemplate, "%ArrayPresentation%", ArrayPresentation);
	MessageTemplate = StrReplace(MessageTemplate, "%ValuesPresentation%", ValuesPresentation);
	
	PreviousValue = Undefined;
	
	For Each Value In ArrayCopy Do
		
		If PreviousValue <> Value Then
			PreviousValue = Value;
			Continue;
		EndIf;
		
		MessageText = StrReplace(MessageTemplate, "%RepeatableValue%", TrimAll(String(Value)));
		#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
			Common.MessageToUser(MessageText);
		#Else
			CommonClient.MessageToUser(MessageText);
		#EndIf
		
		Cancel = True;
		
	EndDo;
	
EndProcedure

// Deletes the values contained in the second array from the first array.
//
// Parameters:
// 	SourceArray - Array -
// 	SubtractedArray - Array -
// 
// Returns:
// 	Array -
//@skip-warning
Function RemoveValuesFromArray(SourceArray, SubtractedArray) Export
	
	Result = CommonClientServer.CopyArray(SourceArray);
	
	For Each CurrentItem In SubtractedArray Do
		CommonClientServer.DeleteValueFromArray(Result, CurrentItem)
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region WorkingWithMobileClient

// Moves all form field headers to the top and sets them to bold, and aligns the form fields to the left
// 
// Parameters:
// 	Items - FormItems - 
// 	Exceptions - Undefined, Array of FormItems - 
Procedure AdaptingFormElementsForMobileScreen(Items, Exceptions = Undefined) Export
	
	BoldFont = New Font(, , True);
	
	For Each Item In Items Do
		If TypeOf(Item) = Type("FormField") And (Exceptions = Undefined Or Exceptions.Find(Item) = Undefined) Then
			
			Item.TitleLocation      = FormItemTitleLocation.Top;
			Item.TitleFont          = BoldFont;
			Item.HorizontalAlign = ItemHorizontalLocation.Left;
			
		ElsIf TypeOf(Item) = Type("FormGroup") Then 
			AdaptingFormElementsForMobileScreen(Item.ChildItems);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region SettingUpBankingDetails

// It serves as a universal procedure for changing the properties of form elements based on the received parameters.
// Parameters are calculated when the object's details are changed.
//
// Parameters:
//  Form - ClientApplicationForm- The form in which you want to set dependent items.
//  ItemDetailsParameters - Array of See AddItemDetailsParameters - Contains a list of properties and their values.
//
Procedure ConfigureDependentFormElements(Form, ItemDetailsParameters) Export
	
	If CommonClientServer.DebugMode() Then
		GeneralPurposeTMServerCall.CheckItemDetailsParameters(ItemDetailsParameters);
	EndIf;
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		If Not ValueIsFilled(AttributeParameters.TagName) Then
			Continue;
		EndIf;
		
		If AttributeParameters.Property = "OnlyViewWithoutBlankMark"
			Or AttributeParameters.Property = "OnlyViewWithoutBlankMarkWithoutClearing" Then
			Form.Items[AttributeParameters.TagName].ReadOnly = AttributeParameters.Value;
			Form.Items[AttributeParameters.TagName].AutoMarkIncomplete = Not AttributeParameters.Value;
		ElsIf AttributeParameters.Property = "OnlyViewWithoutClearing" Then
			Form.Items[AttributeParameters.TagName].ReadOnly = AttributeParameters.Value;
		ElsIf AttributeParameters.Property = "ItemVisibility" Then
			Form.Items[AttributeParameters.TagName].Visible = AttributeParameters.Value;
		Else
			Form.Items[AttributeParameters.TagName][AttributeParameters.Property] = AttributeParameters.Value;
		EndIf;
		If AttributeParameters.Property = "AutoMarkIncomplete"
				And AttributeParameters.Value = False
			Or AttributeParameters.Property = "OnlyViewWithoutBlankMark"
				And AttributeParameters.Value = True
			Or AttributeParameters.Property = "OnlyViewWithoutBlankMarkWithoutClearing"
				And AttributeParameters.Value = True Then
			Form.Items[AttributeParameters.TagName].MarkIncomplete = False;
		EndIf;
	
	EndDo;
	
EndProcedure

// Used to fill in the parameters of the properties of form elements.
// Then these parameters are used in procedures:
//     - Configure the form elements of the Server(), 
//     - General purpose.Disable the check for filling in the object's requirements().
//
// Parameters:
//  AttributeName				 - String - The name of the property that the property is set for (can be empty).
//  TagName					 - String - Name of the form element that the prop is associated with.
//  Property					 - String - Property of the form element. Any property provided by the platform for form elements is allowed.
//                                          In addition, you can use the service properties:
//                                              "Only the view of the Unfilled item" - allows you to set only the view of the item and disable the fill check.
//                                              "Only inspection without cleaning" - allows you to make the field inaccessible without clearing it.
//                                              "Element visibility" - allows you to control only the visibility of the element, and the fill check is not disabled.
//  Value					 - Arbitrary - Any property value.
//  ItemDetailsParameters	 - Array of SeeNewParameterForObjectDetails - The parameters in which you want to add.
//
//  Example:
//  	The general purpose of the Clientserver.Add the parameters of the object's requisit (
//  		"OS.Summation", "Ossummascription", "Visibility", SummaVidima, parameters of the object's requisit).
//
Procedure AddItemDetailsParameters(AttributeName, TagName, Property, Value, ItemDetailsParameters) Export
	
	NewParameter1 = NewParameterForObjectDetails();
	NewParameter1.AttributeName = AttributeName;
	NewParameter1.TagName = TagName;
	NewParameter1.Property = Property;
	NewParameter1.Value = Value;
	
	ItemDetailsParameters.Add(NewParameter1);
	
EndProcedure

// Clears unused banking details.
// 
// Parameters:
//  Object - Arbitrary - The object whose details need to be cleared.
//  ItemDetailsParameters - Array of See NewParameterForObjectDetails - Parameters of the object's details.
//  TabularSectionNames - String - Names of the table parts.
//  ChangedBankingDetails - Array of String - List of changed Bank details.
Procedure ClearUnusedProps(Object, ItemDetailsParameters, TabularSectionNames = "", ChangedBankingDetails = Undefined) Export

	UnusedPropsOfTableParts = New Map;
	
	ObjectTabularSections = New Structure(TabularSectionNames);
	
	If ChangedBankingDetails = Undefined Then
		ChangedBankingDetails = New Array;
	EndIf;

	For Each AttributeParameters In ItemDetailsParameters Do
		
		If Not ValueIsFilled(AttributeParameters.AttributeName) Then
			Continue;
		EndIf;
		
		If AttributeParameters.Property = "Visible" And AttributeParameters.Value = False
			Or (AttributeParameters.Property = "ReadOnly" Or AttributeParameters.Property = "OnlyViewWithoutBlankMark")
					And AttributeParameters.Value = True Then
					
			AttributePath1 = StrSplit(AttributeParameters.AttributeName, ".");
			If AttributePath1.UBound() <> 0 Then
				
				TSAttributes = UnusedPropsOfTableParts.Get(AttributePath1[0]);
				If TSAttributes = Undefined Then
					TSAttributes = New Array;
				EndIf;
				TSAttributes.Add(AttributePath1[1]);
				UnusedPropsOfTableParts.Insert(AttributePath1[0], TSAttributes);
				
			ElsIf TypeOf(Object[AttributeParameters.AttributeName]) = Type("FormDataCollection") 
				Or ObjectTabularSections.Property(AttributeParameters.AttributeName) Then
					
				Object[AttributeParameters.AttributeName].Clear();
				ChangedBankingDetails.Add(AttributeParameters.AttributeName);
				
			Else
				
				Object[AttributeParameters.AttributeName] = Undefined;
				ChangedBankingDetails.Add(AttributeParameters.AttributeName);
				
			EndIf; 
		
		EndIf;
		
	EndDo;
	
	// Clearing PM details
	For Each KeyAndValue In UnusedPropsOfTableParts Do
		For Each RowData In Object[KeyAndValue.Key] Do
			For Each AttributeName In KeyAndValue.Value Do
				RowData[AttributeName] = Undefined;
				ChangedBankingDetails.Add(AttributeName);
			EndDo; 
		EndDo; 
	EndDo; 
	
EndProcedure

// Creates a new description of the object's props parameters.
// 
// Returns:
// 	Structure - with properties:
//      * Value - Number, Boolean -
//      * Property - String -
//      * TagName - String -
//      * AttributeName - String - 
Function NewParameterForObjectDetails() Export

	NewParameter1 = New Structure;
	NewParameter1.Insert("AttributeName");
	NewParameter1.Insert("TagName");
	NewParameter1.Insert("Property");
	NewParameter1.Insert("Value");
	
	Return NewParameter1;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region ValuesBeforeTheChange

// Stores the values prior to the change in the requisite shape
//
// Parameters:
//  Form		 - ClientApplicationForm - Processed form
//  AttributeName - String - name of the item to change
//
Procedure SaveValuesBeforeChanging(Form, AttributeName = Undefined) Export
	
	If Form.ValuesBeforeTheChange = Undefined Then
		
		Form.ValuesBeforeTheChange = Form.DefaultValues;
		
	EndIf;
	
	FillPropertyValues(Form.ValuesBeforeTheChange, Form.ConstantsSet, AttributeName);
	
EndProcedure

// Restores the value before the change in the requisite shape
//
// Parameters:
//  Form		 - ClientApplicationForm - Processed form
//  AttributeName - String - name of the item to change
//
Procedure RestoreValuesBeforeChange(Form, AttributeName) Export
	
	FillPropertyValues(Form.ConstantsSet, Form.ValuesBeforeTheChange, AttributeName);
	
EndProcedure

// Function-Get the value before the change
//
// Parameters:
//  Form		 - ClientApplicationForm - Processed form
//  AttributeName - String - name of the item to change
// 
// Returns:
//  Arbitrary - the value of the props
//
Function GetValueBeforeChange(Form, AttributeName) Export
	
	Return Form.ValuesBeforeTheChange[AttributeName];
	
EndFunction

#EndRegion

#Region MethodsOfWorkingWithRequest

// Adds a selection setting for queries to the collection 
//
// Parameters:
//  Filter               - Map of Structure - collection of selection settings
//  LeftValue       - String       - left selection value in queries
//  RightValue      - String       - right-the value of the selection in queries
//  TypeOfRequestComparison - String       - query comparison type, by default: "In"
//
Procedure AddSelectionItemToCollection(Filter, LeftValue, RightValue, TypeOfRequestComparison = "") Export
	
	TypeOfComparisonRightValue = New Structure;
	
	TypeOfComparisonRightValue.Insert(
		"ComparisonType",
		?(ValueIsFilled(TypeOfRequestComparison),
			TypeOfRequestComparison,
			"In"));
		
	TypeOfComparisonRightValue.Insert("RightValue", RightValue);
		
	Filter.Insert(LeftValue, TypeOfComparisonRightValue);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function DataOnPartsOfPath(Object, DataPathParts, RowID, MeaningOfAbsence = Undefined)
	
	ThisIsForm = TypeOf(Object) = Type("ClientApplicationForm");
	
	If Not ThisIsForm And DataPathParts[0] = "Object" Then // "Object.Props", "Object.Table Part", "Object.The table is missing.Props"
		DataPathParts.Delete(0);
	ElsIf ThisIsForm And DataPathParts[0] = "Form" Then // "Form.Form details", "Form.Form tables", "Form.Form tables.Column"
		DataPathParts.Delete(0);
	ElsIf Not ThisIsForm And DataPathParts[0] = "Form" Then
		Return MeaningOfAbsence;
	EndIf;
	
	
	Data = Object;
	If DataPathParts.Count() > 0 
		And DataPathParts[0] = "Object" Then // An object is a form, "Object.Props", "Object.Table Part", "Object.The table is missing.Props"
		Data = Data[DataPathParts[0]];
		DataPathParts.Delete(0);
	EndIf;
	// Now the Data is a document object or a reference object or the main requisites of the "Object" form or the Client application form
	// The path to the data "Props", "Tabular part", "Tabular part.Props", "Propit1.Props 2"
	// 					"Props forms", "Table forms", "Table forms.Column", "Form details.Props"
	If DataPathParts.Count() > 0 Then
		Data = Data[DataPathParts[0]]; // Table or object/form details
		ValueType = TypeOf(Data);
		
		If Not ThisIsForm Then
			ValueTypeAsString = Upper(StrReplace(String(ValueType)," ",""));
			DocumentReferenceType = Type("DocumentTabularSection.RegisterAdjustment.RegistersTable");
			CatalogReferenceType = Type("CatalogTabularSection.Companies.ContactInformation");
			ReferenceDocumentTypeIsString = Upper(StrReplace(String(DocumentReferenceType)," ",""));
			CatalogReferenceTypeIsString = Upper(StrReplace(String(CatalogReferenceType)," ",""));
			SeparatorPosition = StrFind(ReferenceDocumentTypeIsString,":")-1;
			IsTabularSection = Left(ValueTypeAsString, SeparatorPosition) = Left(ReferenceDocumentTypeIsString, SeparatorPosition)
				Or Left(ValueTypeAsString, SeparatorPosition) = Left(CatalogReferenceTypeIsString, SeparatorPosition);
		Else
			IsTabularSection = ValueType = Type("FormDataCollection");
		EndIf;
		
		If IsTabularSection Then // The data is a table
			If RowID <> Undefined Then // From the table we can get a row or a value in a row
				If ValueType = Type("FormDataCollection") Then
					// There is a form table along the way.
					// If the identifier is specified, then we will return the string
					Data = Data.FindByID(RowID);
				Else
					// We expect the line number in the identifier
					Data = Data[RowID-1];
				EndIf;
				// The data is a string, if you need a value, we will get it from the string
				If DataPathParts.Count() = 2 Then
					Data = Data[DataPathParts[1]];
				EndIf;
			ElsIf DataPathParts.Count() = 2 Then //If the identifier is not specified, we will return the values of the props in the array
				DataArray = New Array;
				For Each TableRow In Data Do
					DataArray.Add(TableRow[DataPathParts[1]]);
				EndDo;
				Data = DataArray;
			EndIf;
		ElsIf DataPathParts.Count() = 2 Then 
			If ValueType = Type("FormDataStructure") 
				Or ValueType = Type("Structure") Then
				Data = Data[DataPathParts[1]]
			Else
				If ValueIsFilled(Data) Then
					Try
						Data = GeneralPurposeTMServerCall.ObjectAttributeValue(Data, DataPathParts[1]);
					Except
						Return MeaningOfAbsence;
					EndTry;
				Else
					Return MeaningOfAbsence;
				EndIf;
			EndIf;
		ElsIf DataPathParts[0] = "Items"
			And DataPathParts.Count() > 2
			And DataPathParts[2] = "CurrentData" Then
			
			NameOfTableElement = DataPathParts[1];
			Data = Object.Items[NameOfTableElement].CurrentData;
			
			If DataPathParts.Count() = 4 Then 
				AttributeName = DataPathParts[3];
				Data = Data[AttributeName];
			EndIf;
			
		EndIf;
	EndIf;
	
	Return Data;
	
EndFunction

Function DocumentSynonym(DocumentNameOrID)
	
	#If Client Then
		Return TMCommonUseClientCached.DocumentSynonym(DocumentNameOrID);
	#Else
		Return GeneralPurposeTMServerCall.DocumentSynonym(DocumentNameOrID);
	#EndIf
	
EndFunction

#EndRegion
