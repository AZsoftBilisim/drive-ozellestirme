#Region Internal

// Returns the names of subsystems to be used in the see Log Log entry.
// 
// Returns:
// 	Structure:
// * ElectronicInteraction - String
// * EDIWithBanks - String
// * ExchangeWithCounterparties - String
// * SharingWithWebsites - String
// * ScheduledJobs - String
// * BusinessNetwork - String
// * TradeOffers - String
// * ProductCrossReferencesMapping - String
// * Cryptography - String
// * InternetConnection - String
// * FilesOperations - String
// * DeliveryService - String
// * ElectronicUISCertification - String
// * CommercialProposals - String
// * ServiceShare - String
// * FileStampingService - String
// * IntegrationOfEDOCenter - String
// * AutomaticReceiptOfEDI - String
// * WorkingWithProductItems - String
// * TEDI - String
Function BadSubsystems() Export
	
	Subsystems = New Structure;
	Subsystems.Insert("ElectronicInteraction", "ElectronicInteraction");
	Subsystems.Insert("EDIWithBanks", "ElectronicInteraction.EDIWithBanks");
	Subsystems.Insert("ExchangeWithCounterparties", "ElectronicInteraction.ExchangeWithCounterparties");
	Subsystems.Insert("SharingWithWebsites", "ElectronicInteraction.SharingWithWebsites");
	Subsystems.Insert("ScheduledJobs", "ScheduledJobs");
	Subsystems.Insert("BusinessNetwork", "ElectronicInteraction.BusinessNetwork");
	Subsystems.Insert("TradeOffers", "ElectronicInteraction.TradeOffers");
	Subsystems.Insert("ProductCrossReferencesMapping",
		"ElectronicInteraction.ProductCrossReferencesMapping");
	Subsystems.Insert("Cryptography", "ElectronicInteraction.Core.Cryptography");
	Subsystems.Insert("InternetConnection", "ElectronicInteraction.Core.InternetConnection");
	Subsystems.Insert("FilesOperations", "ElectronicInteraction.Core.FilesOperations");
	Subsystems.Insert("DeliveryService", "ElectronicInteraction.DeliveryService");
	Subsystems.Insert("ElectronicUISCertification", "ElectronicUISCertification");	
	Subsystems.Insert("CommercialProposals", "ElectronicInteraction.CommercialProposals");
	Subsystems.Insert("ServiceShare", "ElectronicInteraction.ServiceShare");
	Subsystems.Insert("FileStampingService", "ElectronicInteraction.FileStampingService");
	Subsystems.Insert("IntegrationOfEDOCenter", "ElectronicInteraction.ExchangeWithCounterparties.IntegrationOfEDOCenter");
	Subsystems.Insert("AutomaticReceiptOfEDI", "ElectronicInteraction.ExchangeWithCounterparties.AutomaticReceiptOfEDI");
	Subsystems.Insert("WorkingWithProductItems", "ElectronicInteraction.WorkingWithProductItems");
	Subsystems.Insert("TEDI", "ElectronicInteraction.ExchangeWithCounterparties.CrossBorderEDI");
	
	Return Subsystems;
	
EndFunction


// Converts binary data (non-encoded and base64 binary data) to an unencoded value.
// 
// Parameters:
//  BinaryData - BinaryData
// 
// Returns:
//  BinaryData
Function BinaryDecodedData(BinaryData) Export
	DecodedData = GetBinaryDataFromBase64BinaryData(BinaryData);
	If TypeOf(DecodedData) = Type("BinaryData")
			And DecodedData.Size() > 0 Then
		Return DecodedData;
	Else
		Return BinaryData;
	EndIf;
EndFunction

// Supplements the receiver value table with data from the source value table.
// 
// Parameters:
//  SourceTable1 - ValueTable
//  				- TabularSection 
//  				- FormDataCollection
//  DestinationTable - ValueTable
//  				- TabularSection 
//  				- FormDataCollection
//  ColumnName - String
Procedure AddUniqueRowsToTableByColumnValues(SourceTable1, DestinationTable, ColumnName) Export
	If Not ValueIsFilled(ColumnName) Then
		Return;
	EndIf;
	
	For Each SourceRow1 In SourceTable1 Do
		Filter = New Structure(ColumnName, SourceRow1[ColumnName]);
		If Not ValueIsFilled(DestinationTable.FindRows(Filter)) Then
			DestinationRow1 = DestinationTable.Add();
			FillPropertyValues(DestinationRow1, SourceRow1);
		EndIf;
	EndDo;
EndProcedure

// Parameters:
//  CurrencyCode_ - String
// 
// Returns:
//  Undefined,String
Function CurrencySignByCode(CurrencyCode_) Export
	
	CurrencySignsByCodes = New Map;
	CurrencySignsByCodes.Insert("643", "₽");   // Russian Ruble
	CurrencySignsByCodes.Insert("156", "¥");   // Yuan
	CurrencySignsByCodes.Insert("901", "NT$"); // The new Taiwan Dollar
	CurrencySignsByCodes.Insert("840", "$");   // US Dollar
	CurrencySignsByCodes.Insert("978", "€");   // Euro
	
	Return CurrencySignsByCodes[CurrencyCode_];

EndFunction

// Parameters:
//  CRTR - String
// 
// Returns:
//  Boolean
Function ThisIsCheckpointOfBranchOfForeignOrganization(CRTR) Export
	
	TypeDescriptionNumber = New TypeDescription("Number");
	CodeOfReasonForRegistration = TypeDescriptionNumber.AdjustValue(Mid(CRTR, 5, 2));
	// Catalog of reasons for registration of taxpayers-organizations with tax authorities (SPP)
	// from 51 to 99 - for foreign organizations, as prescribed in Int-901.
	Return CodeOfReasonForRegistration >= 51 And CodeOfReasonForRegistration <= 99;
	
EndFunction

#Region WorkingWithDataTrees

// Returns an array consisting of all elements of the tree.
// 
// Parameters:
//  DataTree - Given Tree form, given Tree element form.
// 
// Returns:
//  Array of FormDataTreeItem - tree elements.
//
Function GetAllElementsOfTreeRecursively(DataTree) Export
	
	Result = New Array;
	TreeItemsCollection = DataTree.GetItems();
	
	For Each TreeItem In TreeItemsCollection Do
		Result.Add(TreeItem);
		ItemArray = GetAllElementsOfTreeRecursively(TreeItem);
		CommonClientServer.SupplementArray(Result, ItemArray);
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region CheckingCharacters
 
// Returns an indication that the passed value is or is not a digit.
// Parameters:
//  Char - String
// 
// Returns:
//  Boolean - True if the passed parameter is a digit
Function IsDigit(Val Char) Export
	CharCode = CharCode(Char);
	Return CharCode >= 48 And CharCode <= 57;
EndFunction

// Returns an indication that the passed value is or is not a Latin or Cyrillic letter.
// Parameters:
//  Char - String
// 
// Returns:
//  String - The character is uppercase if the passed value is a letter, otherwise an empty string
Function ThisIsLetter(Val Char) Export
	SymbolUpper = Upper(Char);
	CharCode = CharCode(SymbolUpper);
	Return ?(((CharCode >= 65 And CharCode <= 90) // LatinCharacters
		Or (CharCode >= 1040 And CharCode <= 1071) // CyrillicCharacters
		Or (CharCode = 1025)), // the letter E 
		SymbolUpper, "");
EndFunction

// Returns an indication that the passed value is, or is not, an underscore 
// or a Latin or Cyrillic letter.
// Parameters:
//  Char - String
// 
// Returns:
//  Boolean - True if the passed parameter is a letter or underscore
Function IsItLetterOrUnderscore(Val Char) Export
	Letter = ThisIsLetter(Char);
	Return (Not IsBlankString(Letter)) Or ThisIsUnderscore(Char);
EndFunction

#EndRegion

#Region StringFunctions

// Fiostroka.
// 
// Parameters:
//  FullNameOrSurname - String - LastName
//                - Structure, XDTODataObject - the object that owns the properties Surname, First Name, Patronymic
//  Name - String
//  MiddleName - String
// 
// Call options:
//  Fiostroke(Full name) - an object with the properties Surname, First Name and/or Patronymic is transmitted
//  Fiostrok (Surname, First Name) - formation of a name without a patronymic
//  Fiostroke(Surname, First Name, Patronymic) - forming a full name, if the Patronymic has an empty value, then
//                                       the second option will be formed.
// 
// Returns:
//  String - a string of the form "[Last name] [First name] [Patronymic]" or "[Surname] [Name]" in the absence of a patronymic
Function FullNameString(FullNameOrSurname, Name = "", MiddleName = "") Export
	LastFirstName = New Structure("LastName, Name, MiddleName", "", "", "");
	If TypeOf(FullNameOrSurname) = Type("String") Then
		LastFirstName.LastName = FullNameOrSurname;
		LastFirstName.Name = Name;
		LastFirstName.MiddleName = MiddleName;
	Else
		FillPropertyValues(LastFirstName, FullNameOrSurname);
	EndIf;
	Template = "[LastName] [Name] [MiddleName]";
	If IsBlankString(TrimAll(LastFirstName.MiddleName)) Then
		Template = "[LastName] [Name]";
	EndIf;
	Return StringFunctionsClientServer.InsertParametersIntoString(Template, LastFirstName);
EndFunction

// The function converts the string to date and time.
//
// Parameters:
//  DateTime - String - date in the format "YYYY-MM-DD HH:MM:CC" and its variations with the characters "-", ".", "T" or in the format
//  					 that is processed by the function See StringFunctionsClientServer.StringToDate.
//
// Returns:
//  Date - the value obtained after conversion
//
Function GetDateTimeFromString(Val DateTime) Export
	
	Result = StringFunctionsClientServer.StringToDate(DateTime, DateFractions.DateTime);
	
	If ValueIsFilled(Result) Then
		Return Result;
	EndIf;
	
	DateTime = StrReplace(DateTime, "-", "");
	DateTime = StrReplace(DateTime, ".", "");
	DateTime = StrReplace(DateTime, ":", "");
	If StrLen(DateTime) - StrFind(DateTime, " ") = 5 Then // time in the format H:MM:SS
		DateTime = StrReplace(DateTime, " ", "0");
	ElsIf StrFind(DateTime, "T") > 0 Then // time in the format YYYY MMDDTCHMMSS
		DateTime = StrReplace(DateTime, "T", "");
	Else // time in HH format:MM:SS
		DateTime = StrReplace(DateTime, " ", "");
	EndIf;
	
	TypeDetails = New TypeDescription("Date");
	Result = TypeDetails.AdjustValue(DateTime);  // date and time in the form of "YYYY MMDDHMMSS"
	If Not ValueIsFilled(Result) Then
		Result = TypeDetails.AdjustValue(Left(DateTime, 8));  // only the date "YYYY MMDD"
	EndIf;

	Return Result;
	
EndFunction

#EndRegion

#Region DateInMilliseconds

// Parameters:
//  DateInMilliseconds - Number
// 
// Returns:
//  String - timestamp in the format "dd.MMMM.yyyy HH:mm:ss.SSS."
Function DatePresentationInMilliseconds(DateInMilliseconds) Export
	
	If DateInMilliseconds = 0 Then
		Return "";
	EndIf;
	
	Return Format('00010101' + Int(DateInMilliseconds / 1000), NStr("vi = 'DF=dd.MM.yyyy HH:mm:ss;';
																	|ru = 'ДФ=dd.MM.yyyy HH:mm:ss;';
																	|en = 'DF=MM/dd/yyyy HH:mm:ss;'; fa = 'DF=MM/dd/yyyy HH:mm:ss;';
																	|it = 'DF=MM/dd/yyyy HH:mm:ss;';
																	|pl = 'DF=MM/dd/yyyy HH:mm:ss;';
																	|tr = 'TF=dd.MM.yyyy HH:mm:ss;'"))
		+ "." + Format(DateInMilliseconds % 1000, "ND=3; NZ=000; NLZ=; NG=0");
	
EndFunction

// Parameters:
//  Value - See DatePresentationInMilliseconds
// 
// Returns:
//  Undefined,Number
Function LineInMilliseconds(Value) Export
	
	If IsBlankString(Value) Then
		Return 0;
	EndIf;
	
	NumberOfCharactersMilliseconds = 3;
	MillisecondsOfStringValue = Right(Value, NumberOfCharactersMilliseconds);
	
	DateTimeValuesAsString = Left(Value, StrLen(Value) - NumberOfCharactersMilliseconds - 1);
	DateTimeValues = StringFunctionsClientServer.StringToDate(DateTimeValuesAsString, DateFractions.DateTime);
	If Not ValueIsFilled(DateTimeValues) Then
		Return Undefined;
	EndIf;
	
	Return DateInMilliseconds(DateTimeValues)
		+ StringFunctionsClientServer.StringToNumber(MillisecondsOfStringValue);
	
EndFunction

#EndRegion

#Region MultipleMap

// Multiple matching.
// Used when you need to store a collection of values using one key
// 
// Returns:
//  Map of KeyAndValue:
//  * Key - Arbitrary
//  * Value - Undefined, Array of Arbitrary -
Function NewMultipleMap() Export
	Return New Map;
EndFunction

// Retrieves a collection of values from a multiple key match.
// If nothing was placed on the key, it returns an empty collection.
// 
// The collection is returned by reference, not by value.
// 
// Parameters:
//  MultipleMap - See GeneralPurposeEDLClientServer.NewMultipleMap
//  Var_Key - Arbitrary
// 
// Returns:
//  Array of Arbitrary
Function GetFromMultipleMap(MultipleMap, Var_Key) Export
	Value = MultipleMap.Get(Var_Key);
	If Value = Undefined Then
		Collection = New Array;
		MultipleMap.Insert(Var_Key, Collection);
	Else
		Collection = Value;
	EndIf;
	Return Collection;
EndFunction

// Inserts a new value into the multiple match collection.
// The collection does not control the uniqueness of the values, but preserves the order in which elements are inserted.
// 
// Parameters:
//  MultipleMap - See GeneralPurposeEDLClientServer.NewMultipleMap
//  Var_Key - Arbitrary
//  Value - Arbitrary
Procedure InsertIntoMultipleMap(MultipleMap, Var_Key, Value) Export
	GetFromMultipleMap(MultipleMap, Var_Key).Add(Value);
EndProcedure

#EndRegion

#Region WorkingWithCollections

// Parameters:
//  List - ValueList
//  BeginningOfTheLine - String
// 
Procedure DeleteValuesAtBeginningOfLine(List, BeginningOfTheLine) Export
	If Not TypeOf(List) = Type("ValueList") Then
		Return;
	EndIf;
	
	CollectionItemsCount = List.Count();
	
	For ReverseIndex = 1 To CollectionItemsCount Do
		
		IndexOf = CollectionItemsCount - ReverseIndex;
		
		ValueFromList = List[IndexOf].Value;
		If TypeOf(ValueFromList) = Type("String") And StrStartsWith(ValueFromList, BeginningOfTheLine) Then
			
			List.Delete(IndexOf);
			
		EndIf;
		
	EndDo;
EndProcedure

// Parameters:
//  Structure - Structure
// 
// Returns:
//  Boolean 
//
Function ThisIsStructureWithEmptyValues(Structure) Export
	Result = True;
	For Each KeyValue In Structure Do
		If ValueIsFilled(KeyValue.Value) Then
			Result = False;
			Break;
		EndIf;
	EndDo;
	Return Result;
EndFunction

// A function to search for a value in a structure
// Parameters:
//   Data - Structure
//   ValueForSearch - Arbitrary
// Returns:
//   Boolean - True if the value is found
Function StructureContainsValue(Data, ValueForSearch) Export
	For Each Item In Data Do
		If Item.Value = ValueForSearch Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

#EndRegion

#EndRegion

#Region Private

// Returns an indication that the passed value is or is not an underscore.
// Parameters:
//  Char - String
// 
// Returns:
//  Boolean - True if the passed parameter is an underscore
Function ThisIsUnderscore(Val Char)
	CharCode = CharCode(Char);
	Return (CharCode = 95);
EndFunction

// Parameters:
//  DateTime - Date
// 
// Returns:
//  Number
Function DateInMilliseconds(DateTime)
	
	Return (DateTime - '00010101') * 1000;
	
EndFunction

#EndRegion