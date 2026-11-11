#Region Public

// The function returns the GS1 separator.
//
// Returns:
//  String
//
Function GS1Separator() Export;
	
	Return Char(29); // Dec 29
	
EndFunction

// The function returns the escaped GS1 character.
//
// Returns:
//  String
//
Function EscapedCharacterGS1() Export;
	
	Return "\x1d"; // Used to escape the GS1 character.
	
EndFunction


#EndRegion
 
#Region Internal

// Splits a string into multiple lines by the specified separator. The separator can have any length.
// In cases where the delimiter is a single-character string and the shorten printable Characters parameter is not used,
// we recommend using the split platform function.
//
// Parameters:
//  Value               - String - delimited text.
//  Separator            - String - text line separator, at least 1 character.
//  SkipEmptyStrings - Boolean - indicates whether blank lines should be included in the result.
//    If the parameter is not specified, then the function works in compatibility mode with its previous version.:
//     > for the space separator, empty lines are not included in the result, for other separators, empty lines
//       are included in the result;
//     > if the String parameter does not contain significant characters or does not contain a single character (empty string), then in
//       the case of a space separator, the result of the function will be an array containing a single value "" (empty string), and
//       with other delimiters, the result of the function will be an empty array.
//  TrimNonprintableChars - Boolean - shorten non-printable characters along the edges of each substring found.
//
// Returns:
//  Array of String
//
// Example:
//  Strokemymouse.Decompose a string into an array of substrings (", one,, two,", ",")
//  - returns an array of 5 elements, three of which are empty: "", "one","", " two", "";
//  Strokemymouse.Decompose stringmassive substrings (", one,, two,",",", True)
//  - returns an array of two elements: "one", " two";
//  Strokemymouse.Decompose a string into a substring array ("one two "," ")
//  - returns an array of two elements: "one", " two";
//  Strokemymouse.Maslojirpisheprom("")
//  - returns an empty array;
//  Strokemymouse.Decompose stringmassive substrings ("",, False)
//  - returns an array with one element: ""(empty string);
//  Strokemymouse.Decompose stringmassive substrings ("", " ")
//  - returns an array with one element: "" (empty string).
//
Function SplitStringIntoSubstringsArray(Val Value, Val Separator = ",", Val SkipEmptyStrings = Undefined, 
	TrimNonprintableChars = False) Export
	
	If StrLen(Separator) = 1 
		And SkipEmptyStrings = Undefined 
		And TrimNonprintableChars Then 
		
		Result = StrSplit(Value, Separator, False);
		For IndexOf = 0 To Result.UBound() Do
			Result[IndexOf] = TrimAll(Result[IndexOf])
		EndDo;
		Return Result;
		
	EndIf;
	
	Result = New Array;
	
	// For backward compatibility.
	If SkipEmptyStrings = Undefined Then
		SkipEmptyStrings = ?(Separator = " ", True, False);
		If IsBlankString(Value) Then 
			If Separator = " " Then
				Result.Add("");
			EndIf;
			Return Result;
		EndIf;
	EndIf;
	//
	
	Position = StrFind(Value, Separator);
	While Position > 0 Do
		Substring = Left(Value, Position - 1);
		If Not SkipEmptyStrings Or Not IsBlankString(Substring) Then
			If TrimNonprintableChars Then
				Result.Add(TrimAll(Substring));
			Else
				Result.Add(Substring);
			EndIf;
		EndIf;
		Value = Mid(Value, Position + StrLen(Separator));
		Position = StrFind(Value, Separator);
	EndDo;
	
	If Not SkipEmptyStrings Or Not IsBlankString(Value) Then
		If TrimNonprintableChars Then
			Result.Add(TrimAll(Value));
		Else
			Result.Add(Value);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction 

// Parses the URI string into its component parts and returns it as a structure.
// Based on RFC 3986.
//
// Parameters:
//     URIString1 - String - link to a resource in the format:
//                          <schema>://<login>:<password>@<host>:<port>/<path>?<parameters>#<anchor>.
//
// Returns:
//     Structure - URI components according to the format:
//         * Schema         - String
//         * Login         - String
//         * Password        - String
//         * ServerName    - String - part <host>:< port> of the input parameter.
//         * Host          - String
//         * Port          - Undefined, Number -
//         * PathAtServer - String - the <path>part?<characteristic>#< anchor> of the input parameter.
//
Function URIStructure(Val URIString1) Export
	
	URIString1 = TrimAll(URIString1);
	
	// Schema
	Schema = "";
	Position = Find(URIString1, "://");
	If Position > 0 Then
		Schema = Lower(Left(URIString1, Position - 1));
		URIString1 = Mid(URIString1, Position + 3);
	EndIf;

	// The connection string and the path on the server.
	ConnectionString = URIString1;
	PathAtServer = "";
	Position = Find(ConnectionString, "/");
	If Position > 0 Then
		PathAtServer = Mid(ConnectionString, Position + 1);
		ConnectionString = Left(ConnectionString, Position - 1);
	EndIf;
		
	// User information and server name.
	AuthorizationString = "";
	ServerName = ConnectionString;
	Position = Find(ConnectionString, "@");
	If Position > 0 Then
		AuthorizationString = Left(ConnectionString, Position - 1);
		ServerName = Mid(ConnectionString, Position + 1);
	EndIf;
	
	// login and password
	Login = AuthorizationString;
	Password = "";
	Position = Find(AuthorizationString, ":");
	If Position > 0 Then
		Login = Left(AuthorizationString, Position - 1);
		Password = Mid(AuthorizationString, Position + 1);
	EndIf;
	
	// Host and port
	Host = ServerName;
	Port = "";
	Position = Find(ServerName, ":");
	If Position > 0 Then
		Host = Left(ServerName, Position - 1);
		Port = Mid(ServerName, Position + 1);
	EndIf;
	
	Result = New Structure;
	Result.Insert("Schema", Schema);
	Result.Insert("Login", Login);
	Result.Insert("Password", Password);
	Result.Insert("ServerName", ServerName);
	Result.Insert("Host", Host);
	Result.Insert("Port", ?(IsBlankString(Port), Undefined, Number(Port)));
	Result.Insert("PathAtServer", PathAtServer);
	
	Return Result;
	
EndFunction

// Returns True if the client application is a mobile client.
//
// Returns:
//  Boolean - if there is no client application, False is returned.
//
Function IsMobileClient() Export
	
#If MobileClient Then
	Return True;
#ElsIf Server Or ThickClientOrdinaryApplication Then

	IsMobileClient = False;
	
	If IsMobileClient = Undefined Then
		Return False; // There is no client application.
	EndIf;
	
	Return IsMobileClient;
#Else
	Return False;
#EndIf

EndFunction

// Creates an array and puts the passed value in it.
//
// Parameters:
//  Value - Arbitrary - any value.
//
// Returns:
//  Array of Arbitrary - an array of one element.
//
Function ValueInArray(Value) Export
	
	Array = New Array;
	Array.Add(Value);
	
	Return Array;
	
EndFunction

// Base64 to barcode.
// 
// Parameters:
//  BarcodeInBase64 - String - Barcode in base64
// 
// Returns:
//  String - Base64 to Barcode
Function Base64BBarcode(BarcodeInBase64) Export
	
	BinaryData = Base64Value(BarcodeInBase64);
	If BinaryData = Undefined Then
		Barcode = BarcodeInBase64;
	Else
		Barcode = GetStringFromBinaryData(BinaryData);
	EndIf;
	
	Return Barcode;
	
EndFunction

// Barcode in base64.
// 
// Parameters:
//  Barcode - String - Barcode
// 
// Returns:
//  String - Barcode in base64
Function BarcodeInBase64(Barcode) Export
	
	If Barcode = Undefined Then 
		RowBinaryData = Undefined;
	Else
		RowBinaryData = GetBinaryDataFromString(Barcode);
		BarcodeBASE64 = Base64String(RowBinaryData);
		BarcodeBASE64 = StrReplace(BarcodeBASE64, Chars.LF, "");
		BarcodeBASE64 = StrReplace(BarcodeBASE64, Chars.CR, "");
	EndIf;
	
	Return BarcodeBASE64; 
	
EndFunction

// The function returns the RS separator.
//
// Returns:
//  String
//
Function RSSeparator() Export;
	
	Return Char(30); // Dec 30
	
EndFunction

// The function returns the escaped character RS.
//
// Returns:
//  String
//
Function EscapedCharacterIsRS() Export;
	
	Return "\x1e"; // Used to escape the RS symbol.
	
EndFunction  

// The function returns the EOT separator.
//
// Returns:
//  String
//
Function EOTSeparator() Export;
	
	Return Char(4); // Dec 4
	
EndFunction

// The function returns the escaped character EOT.
//
// Returns:
//  String
//
Function EscapedEOTCharacter() Export;
	
	Return "\x4"; // Used to escape the EOT symbol.
	
EndFunction

// Convert TimeStamp to Date
// Parameters:
//  Timestamp - String, Number - a value containing a time stamp
//  
// Returns:
//  Date
// 
Function TimestampInDate(Timestamp) Export
	Try
		Return Date("19700101")+(?(TypeOf(Timestamp) = Type("String"), Number(Timestamp), Timestamp) / 1000);
	Except
		Return Undefined;
	EndTry;
EndFunction

// Convert date to TimeStamp
//  
// Parameters:
//  Date - Date - the date you want to convert
//  
// Returns:
//  String
// 
Function DateInTimestamp(Date = Undefined) Export
	
	Return Format(Number(?(TypeOf(Date) = Type("Date"), Date, CurrentDate()) - Date("19700101")),"NZ=0; NG=0");
	
EndFunction

Function PresentationRevisionOfInterface(InterfaceRevision) Export
	
	If InterfaceRevision >= 5000 Then
		Result = "5." + String(InterfaceRevision - 5000);
	ElsIf InterfaceRevision >= 4000 Then
		Result = "4." + String(InterfaceRevision - 4000);
	ElsIf InterfaceRevision >= 3000 Then
		Result = "3." + String(InterfaceRevision - 3000);
	ElsIf InterfaceRevision >= 2000 Then
		Result = "2." + String(InterfaceRevision - 2000);
	ElsIf InterfaceRevision > 1000 Then
		Result = "1." + String(InterfaceRevision - 1000);
	Else
		Result = "";
	EndIf;
	
	Return Result;
	
EndFunction

// Generates a string of repeated characters of the specified length.
//
// Parameters:
//  Char      - String - the character that the string will be formed from.
//  StringLength - Number  - required length of the resulting string.
//
// Returns:
//  String - a string consisting of repeated characters.
//
Function GenerateCharacterString(Val Char, Val StringLength) Export
	
	Result = "";
	For Counter = 1 To StringLength Do
		Result = Result + Char;
	EndDo;
	
	Return Result;
	
EndFunction

// Converts the source string to a number without calling exceptions.
//
// Parameters:
//   Value - String - the string to be converted to a number.
//                       For example, "10", "+10", "010", will return 10;
//                                 "(10)", "-10", will return -10;
//                                 "10,2", "10.2", will return 10.2;
//                                 "000", " ", "", will return 0;
//                                 "10text", will return Indeterminate.
//
// Returns:
//   Number, Undefined - the resulting number, or Undefined if the string is not a number.
//
Function StringToNumber(Val Value) Export
	
	Value  = StrReplace(Value, " ", "");
	If StrStartsWith(Value, "(") Then
		Value = StrReplace(Value, "(", "-");
		Value = StrReplace(Value, ")", "");
	EndIf;
	
	StringWithoutZeroes = StrReplace(Value, "0", "");
	If IsBlankString(StringWithoutZeroes) Or StringWithoutZeroes = "-" Then
		Return 0;
	EndIf;
	
	NumberType  = New TypeDescription("Number");
	Result = NumberType.AdjustValue(Value);
	
	Return ?(Result <> 0 And Not IsBlankString(StringWithoutZeroes), Result, Undefined);
	
EndFunction

// Returns the value of a property from a structure or nested object by name
// containing dots. If there is no intermediate property, it returns
// the default value without generating an exception.
//
// Parameters:
//  Structure           - Structure - the source object from which the value is extracted.
//  PropertyName         - String - the path to the property where the nesting levels are separated by a dot.
//                        For example: "Attribute", "Counterparty.Name", 
//                                  "data.verification_details.raw_data.sign".
//  DefaultValue - Arbitrary - The value returned if the property is not found.
//                        Default = "" (empty string).
//
// Returns:
//  Arbitrary - The value of the requested property, if it exists on the specified path,
//                 or the value of silence otherwise.
//
// Example:
//  Data = New Structure("Counterparty", New Structure("Name, TIN", "LLC Romashka", "7701234567"));
//  Result = Get the property safely (Data, "Counterparty.Name", "Not specified");
//  Result = "LLC Camomile"
//
Function StructurePropertyIsSafe(Structure, PropertyName, DefaultValue = "") Export
	
	Value = Structure;
	Properties = StrSplit(PropertyName, ".");
	For Each Item In Properties Do
		
		If Not Value.Property(Item, Value) Then
			Return DefaultValue;
		EndIf;
		
		If TypeOf(Value) <> Type("Structure") Then
			Return Value;
		EndIf;
		
	EndDo;
	
	Return Value;
	
EndFunction

#Region WorkingWithXML

// The function reads the XML root element.
//
// Parameters:
//  XMLLine - String - XML string.
//
// Returns:
//  Structure
//
Function ReadRootXMLElement(XMLLine) Export
	
	Result = New Structure();     
#If Not WebClient Then 
	If Not IsBlankString(XMLLine) Then
		XMLReader = New XMLReader; 
		XMLReader.SetString(XMLLine);
		XMLReader.MoveToContent();
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			If XMLReader.AttributeCount() > 0 Then
				While XMLReader.ReadAttribute() Do
					Result.Insert(XMLReader.Name, XMLReader.Value);
				EndDo
			EndIf;
		EndIf;
	EndIf;
#EndIf
	Return Result;
	
EndFunction     

// The function reads parameters from XML.
//
// Parameters:
//  XMLLine - String - XML string.
//
// Returns:
//  Structure
//
Function ReadParametersFromXML(XMLLine) Export
	
	Result = New Structure();
#If Not WebClient Then 
	If Not IsBlankString(XMLLine) Then
		XMLReader = New XMLReader; 
		XMLReader.SetString(XMLLine);
		XMLReader.MoveToContent();
		If XMLReader.Name = "Parameters" And XMLReader.NodeType = XMLNodeType.StartElement Then  
			While XMLReader.Read() Do  
				If XMLReader.Name = "Parameter" And XMLReader.NodeType = XMLNodeType.StartElement Then  
					Name = XMLReader.AttributeValue("Name"); 
					Value = XMLReader.AttributeValue("Value");  
					Result.Insert(Name, Value);
				EndIf;
			EndDo;
		EndIf;
	EndIf;        
#EndIf
	Return Result; 
	
EndFunction     

#EndRegion

#Region Internet

// Creates
// an OpenSSL secure connection description object. See also OpenSSL Secure Connection object description in the Syntax Helper.
//
// Parameters:
//  ClientCertificate - FileClientCertificate
//                    - WindowsClientCertificate
//                    - Undefined - OpenSSL client certificate.
//  CertificationAuthorityCertificates - FileCertificationAuthorityCertificates
//                                   - WindowsCertificationAuthorityCertificates
//                                   - LinuxCertificationAuthorityCertificates
//                                   - OSCertificationAuthorityCertificates
//                                   - Undefined - certificates of OpenSSL certification centers. 
//
// Returns:
//  OpenSSLSecureConnection
//
Function NewSecureConnection(Val ClientCertificate = Undefined, Val CertificationAuthorityCertificates = Undefined) Export
	
	SecureConnection = Undefined;
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If CommonCEL.BSPIsUsed() Then
		
		// Calling BSP
		GeneralPurposeModule = CommonCEL.CommonModule("CommonClientServer");
		SecureConnection = GeneralPurposeModule.NewSecureConnection(ClientCertificate, CertificationAuthorityCertificates);
		// The end of the BSP Challenge 
		
	EndIf;
#Else
	
	If CommonCELClient.BSPIsUsed() Then
		
		// Calling BSP
		GeneralPurposeModule = CommonCELClient.CommonModule("CommonClientServer");
		SecureConnection = GeneralPurposeModule.NewSecureConnection(ClientCertificate, CertificationAuthorityCertificates);
		// The end of the BSP Challenge 
		
	EndIf;
#EndIf
	
	If SecureConnection = Undefined Then
		
		#If WebClient Or MobileClient Or MobileAppClient Then 
			SecureConnection = New OpenSSLSecureConnection;
		#Else
			If CertificationAuthorityCertificates = Undefined Then
				VersionsOf1CEnterpriseForCertificateUsage = "8.3.22.2470; 8.3.23.2122; 8.3.24.1446";
				
				SystemInfo = New SystemInfo;
				VersionCurrentNumber = ConfigurationVersionWithoutBuildNumber(SystemInfo.AppVersion);
				ShouldUseCertificatesFromCAs = CompareVersionsWithoutBuildNumber(VersionCurrentNumber, "8.3.21") > 0;
				
				If ShouldUseCertificatesFromCAs Then
					If CompareVersionsWithoutBuildNumber(VersionCurrentNumber, "8.3.25") < 0 Then
						For Each BuildNumber In StrSplit(VersionsOf1CEnterpriseForCertificateUsage, "; ", False) Do
							If StrStartsWith(BuildNumber, VersionCurrentNumber + ".") Then
								ShouldUseCertificatesFromCAs = 
								CompareVersions(SystemInfo.AppVersion, BuildNumber) >= 0;
								Break;
							EndIf;
						EndDo;
					EndIf;
					
					If ShouldUseCertificatesFromCAs Then
						CertificationAuthorityCertificates = New OSCertificationAuthorityCertificates();
					EndIf;
				EndIf;
			EndIf;
			
			SecureConnection = New OpenSSLSecureConnection(ClientCertificate, CertificationAuthorityCertificates);
		#EndIf
		
	EndIf; 
	
	Return SecureConnection;
	
EndFunction

#EndRegion

// Checks whether an arbitrary object has a prop or property without accessing metadata.
//
// Parameters:
//  Object       - Arbitrary - the object to check for the presence of a prop or property;
//  AttributeName - String       - name of the item or property.
//
// Returns:
//  Boolean - The truth, if there is.
//
Function HasAttributeOrObjectProperty(Object, AttributeName) Export
	
	UniqueKey   = New UUID;
	AttributeStructure = New Structure(AttributeName, UniqueKey);
	FillPropertyValues(AttributeStructure, Object);
	
	Return AttributeStructure[AttributeName] <> UniqueKey;
	
EndFunction

// Checks whether the string contains only numbers.
//
// Parameters:
//  Value         - String - the string to check.
//  Obsolete1       - Boolean - deprecated parameter, not used.
//  SpacesProhibited - Boolean - if False, spaces are allowed in the string.
//
// Returns:
//   Boolean - True - the string contains only numbers or is empty, False - the string contains other characters.
//
// Example:
//  Result = Only if the line is broken("0123"); // True
//  Result = Only if the string is broken("0123abc"); // False
//  Result = Only if the string is broken("01 2 3",, False); // True
//
Function OnlyNumbersInString(Val Value, Val Obsolete1 = True, Val SpacesProhibited = True) Export
	
	If TypeOf(Value) <> Type("String") Then
		Return False;
	EndIf;
	
	If Not SpacesProhibited Then
		Value = StrReplace(Value, " ", "");
	EndIf;
		
	If StrLen(Value) = 0 Then
		Return True;
	EndIf;
	
	// If it contains only digits, then an empty string should be obtained as a result of substitutions.
	// It is impossible to check with an empty string, since there may be whitespace characters in the source string.
	Return StrLen(
		StrReplace( StrReplace( StrReplace( StrReplace( StrReplace(
		StrReplace( StrReplace( StrReplace( StrReplace( StrReplace( 
			Value, "0", ""), "1", ""), "2", ""), "3", ""), "4", ""), "5", ""), "6", ""), "7", ""), "8", ""), "9", "")) = 0;
	
EndFunction

Function LaunchStringIsSafe(CommandLine1) Export
	// String data that does not contain the following characters are considered safe: "$", "`", "|", "||" ";", "&", "&&".
	DangerousCall = StrFind(CommandLine1, "$")>0
		Or StrFind(CommandLine1, "`")>0
		Or StrFind(CommandLine1, "|")>0
		Or StrFind(CommandLine1, "||")>0
		Or StrFind(CommandLine1, ";")>0
		Or StrFind(CommandLine1, "&")>0
		Or StrFind(CommandLine1, "&&")>0;
	Return Not DangerousCall;
EndFunction

Function SessionDate() Export
	Return CommonCELInternalServerCall.SessionDate();
EndFunction

// Convert ID to string with spaces
//
// Parameters:
//  Id - String - ID to convert
//
// Returns:
//  String - id converted to readable format
Function IDPresentation(Id) Export
	
	LineSize = StrLen(Id);
	Result = "";
	For Number=1 To LineSize Do
		CharCode = CharCode(Id, Number);
		NextCharacterCode = CharCode(Id, Number + 1);
		SymbolClass = "";
		If CharCode >= CharCode("a") And CharCode <= CharCode("Z2") Then
			Result = Result + Char(CharCode);
		ElsIf CharCode >= CharCode("a") And CharCode <= CharCode("z") Then
			Result = Result + Char(CharCode);
		ElsIf CharCode >= CharCode("A") And CharCode <= CharCode("Z2") Then
			If Number = 1 Then 
				Result = Result + Char(CharCode);
			Else
				CodeOfPreviousCharacter = CharCode(Id, Number - 1);
				If CodeOfPreviousCharacter >= CharCode("0") And CodeOfPreviousCharacter <= CharCode("9") Then
					Result = Result + Char(CharCode);
				ElsIf CodeOfPreviousCharacter >= CharCode("A") And CodeOfPreviousCharacter <= CharCode("Z") Then
					Result = Result + Char(CharCode);
				ElsIf CodeOfPreviousCharacter >= CharCode("A") And CodeOfPreviousCharacter <= CharCode("Z2") Then
					Result = Result + Char(CharCode);
				ElsIf NextCharacterCode >= CharCode("A") And NextCharacterCode <= CharCode("Z2") Then
					Result = Result + " " + Char(CharCode);
				Else
					Result = Result + " " + Lower(Char(CharCode));
				EndIf;
			EndIf;
		ElsIf CharCode >= CharCode("A") And CharCode <= CharCode("Z") Then
			If Number = 1 Then
				Result = Result + Char(CharCode);
			Else
				CodeOfPreviousCharacter = CharCode(Id, Number - 1);
				If CodeOfPreviousCharacter >= CharCode("A") And CodeOfPreviousCharacter <= CharCode("Z") Then
					Result = Result + Char(CharCode);
				ElsIf CodeOfPreviousCharacter = CharCode("_") Then
					Result = Result + Char(CharCode);
				Else
					Result = Result + " " + Char(CharCode);
				EndIf;
			EndIf;
		ElsIf CharCode >= CharCode("0") And CharCode <= CharCode("9") Then
			If Number = 1 Then
				Result = Result + Char(CharCode);
			Else
				CodeOfPreviousCharacter = CharCode(Id, Number - 1);
				If CodeOfPreviousCharacter >= CharCode("0") And CodeOfPreviousCharacter <= CharCode("9") Then
					Result = Result + Char(CharCode);
				ElsIf CodeOfPreviousCharacter >= CharCode("A") And CodeOfPreviousCharacter <= CharCode("Z") Then
					Result = Result + Char(CharCode);
				ElsIf CodeOfPreviousCharacter >= CharCode("A") And CodeOfPreviousCharacter <= CharCode("Z2") Then
					Result = Result + Char(CharCode);
				Else
					Result = Result + " " + Char(CharCode);
				EndIf;
			EndIf;
		ElsIf CharCode = CharCode("_") Then
			Result = Result + Char(CharCode);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Gets the configuration version number without the build number.
//
// Parameters:
//  Version - String - configuration version in the format PP. PP. ZZ. SS,
//                    where SS is the build number to be deleted.
// 
// Returns:
//  String - configuration version number without build number in PP.PP.ZZ format.
//
Function ConfigurationVersionWithoutBuildNumber(Val Version) Export
	
	Array = StrSplit(Version, ".");
	
	If Array.Count() < 3 Then
		Return Version;
	EndIf;
	
	Result = "[Edition].[Subedition].[Release]";
	Result = StrReplace(Result, "[Edition]",    Array[0]);
	Result = StrReplace(Result, "[Subedition]", Array[1]);
	Result = StrReplace(Result, "[Release]",       Array[2]);
	
	Return Result;
EndFunction

// Compare two version strings.
//
// Parameters:
//  VersionString1  - String - version number in the format PP. {P|PP}. ZZ.
//  VersionString2  - String - the second version number to compare.
//
// Returns:
//   Number   - greater than 0 if version string1 > version string2; 0 if versions are equal.
//
Function CompareVersionsWithoutBuildNumber(Val VersionString1, Val VersionString2) Export
	
	String1 = ?(IsBlankString(VersionString1), "0.0.0", VersionString1);
	String2 = ?(IsBlankString(VersionString2), "0.0.0", VersionString2);
	Version1 = StrSplit(String1, ".");
	If Version1.Count() <> 3 Then
		Raise SubstituteParametersToString(
			NStr("vi = 'Sai định dạng tham số %1: %2';
				|ru = 'Неправильный формат параметра %1: %2';
				|en = 'Invalid %1 parameter format: %2'; fa = 'Invalid %1 parameter format: %2';
				|it = 'Formato non corretto del parametro %1: %2';
				|pl = 'Nieprawidłowy format parametru %1: %2';
				|tr = 'Yanlış parametre biçimi%1:%2'"), "VersionString1", VersionString1);
	EndIf;
	Version2 = StrSplit(String2, ".");
	If Version2.Count() <> 3 Then
		Raise SubstituteParametersToString(
	    	NStr("vi = 'Sai định dạng tham số %1: %2';
				|ru = 'Неправильный формат параметра %1: %2';
				|en = 'Invalid %1 parameter format: %2'; fa = 'Invalid %1 parameter format: %2';
				|it = 'Formato non corretto del parametro %1: %2';
				|pl = 'Nieprawidłowy format parametru %1: %2';
				|tr = 'Yanlış parametre biçimi%1:%2'"), "VersionString2", VersionString2);
	EndIf;
	
	Result = 0;
	For Digit = 0 To 2 Do
		Result = Number(Version1[Digit]) - Number(Version2[Digit]);
		If Result <> 0 Then
			Return Result;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Compare two version strings.
//
// Parameters:
//  VersionString1  - String - version number in the format PP. {P|PP}. ZZ. SS.
//  VersionString2  - String - the second version number to compare.
//
// Returns:
//   Number   - greater than 0 if version string1 > version string2; 0 if versions are equal.
//
Function CompareVersions(Val VersionString1, Val VersionString2) Export
	
	String1 = ?(IsBlankString(VersionString1), "0.0.0.0", VersionString1);
	String2 = ?(IsBlankString(VersionString2), "0.0.0.0", VersionString2);
	Version1 = StrSplit(String1, ".");
	If Version1.Count() <> 4 Then
		Raise SubstituteParametersToString(
			NStr("vi = 'Sai định dạng tham số %1: %2';
				|ru = 'Неправильный формат параметра %1: %2';
				|en = 'Invalid %1 parameter format: %2'; fa = 'Invalid %1 parameter format: %2';
				|it = 'Formato non corretto del parametro %1: %2';
				|pl = 'Nieprawidłowy format parametru %1: %2';
				|tr = 'Yanlış parametre biçimi%1:%2'"), "VersionString1", VersionString1);
	EndIf;
	Version2 = StrSplit(String2, ".");
	If Version2.Count() <> 4 Then
		Raise SubstituteParametersToString(
	    	NStr("vi = 'Sai định dạng tham số %1: %2';
				|ru = 'Неправильный формат параметра %1: %2';
				|en = 'Invalid %1 parameter format: %2'; fa = 'Invalid %1 parameter format: %2';
				|it = 'Formato non corretto del parametro %1: %2';
				|pl = 'Nieprawidłowy format parametru %1: %2';
				|tr = 'Yanlış parametre biçimi%1:%2'"), "VersionString2", VersionString2);
	EndIf;
	
	Result = 0;
	For Digit = 0 To 3 Do
		Result = Number(Version1[Digit]) - Number(Version2[Digit]);
		If Result <> 0 Then
			Return Result;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Substitutes parameters in a string. The maximum possible number of parameters is 9.
// Parameters in the string are set as %<parameter number>. Parameters are numbered starting from one.
//
// Parameters:
//  StringPattern  - String - string template with parameters (occurrences of the form " %<parameter number>", 
//                           for example " %1 went to %2");
//  Parameter1   - String - the value of the parameter to be substituted.
//  Parameter2   - String
//  Parameter3   - String
//  Parameter4   - String
//  Parameter5   - String
//  Parameter6   - String
//  Parameter7   - String
//  Parameter8   - String
//  Parameter9   - String
//
// Returns:
//  String   - a text string with substituted parameters.
//
// Example:
//  stringfunctionclientserver.Substitute a string parameter (NStr("ru='%1 went to %2'"), "Vasya", "Zoo") = "Vasya went
//  to the Zoo."
//
Function SubstituteParametersToString(Val StringPattern,
	Val Parameter1, Val Parameter2 = Undefined, Val Parameter3 = Undefined,
	Val Parameter4 = Undefined, Val Parameter5 = Undefined, Val Parameter6 = Undefined,
	Val Parameter7 = Undefined, Val Parameter8 = Undefined, Val Parameter9 = Undefined) Export
	
	HasParametersWithPercentageChar = StrFind(Parameter1, "%")
		Or StrFind(Parameter2, "%")
		Or StrFind(Parameter3, "%")
		Or StrFind(Parameter4, "%")
		Or StrFind(Parameter5, "%")
		Or StrFind(Parameter6, "%")
		Or StrFind(Parameter7, "%")
		Or StrFind(Parameter8, "%")
		Or StrFind(Parameter9, "%");
		
	If HasParametersWithPercentageChar Then
		Return SubstituteParametersWithPercentageChar(StringPattern, Parameter1,
			Parameter2, Parameter3, Parameter4, Parameter5, Parameter6, Parameter7, Parameter8, Parameter9);
	EndIf;
	
	StringPattern = StrReplace(StringPattern, "%1", Parameter1);
	StringPattern = StrReplace(StringPattern, "%2", Parameter2);
	StringPattern = StrReplace(StringPattern, "%3", Parameter3);
	StringPattern = StrReplace(StringPattern, "%4", Parameter4);
	StringPattern = StrReplace(StringPattern, "%5", Parameter5);
	StringPattern = StrReplace(StringPattern, "%6", Parameter6);
	StringPattern = StrReplace(StringPattern, "%7", Parameter7);
	StringPattern = StrReplace(StringPattern, "%8", Parameter8);
	StringPattern = StrReplace(StringPattern, "%9", Parameter9);
	Return StringPattern;
	
EndFunction

// Inserts parameters into a string, considering that the parameters can use the wildcard words %1, %2, and so on.
Function SubstituteParametersWithPercentageChar(Val SubstitutionString,
	Val Parameter1, Val Parameter2 = Undefined, Val Parameter3 = Undefined,
	Val Parameter4 = Undefined, Val Parameter5 = Undefined, Val Parameter6 = Undefined,
	Val Parameter7 = Undefined, Val Parameter8 = Undefined, Val Parameter9 = Undefined)
	
	Result = "";
	Position = StrFind(SubstitutionString, "%");
	While Position > 0 Do 
		Result = Result + Left(SubstitutionString, Position - 1);
		CharAfterPercentage = Mid(SubstitutionString, Position + 1, 1);
		ParameterToSubstitute = Undefined;
		If CharAfterPercentage = "1" Then
			ParameterToSubstitute = Parameter1;
		ElsIf CharAfterPercentage = "2" Then
			ParameterToSubstitute = Parameter2;
		ElsIf CharAfterPercentage = "3" Then
			ParameterToSubstitute = Parameter3;
		ElsIf CharAfterPercentage = "4" Then
			ParameterToSubstitute = Parameter4;
		ElsIf CharAfterPercentage = "5" Then
			ParameterToSubstitute = Parameter5;
		ElsIf CharAfterPercentage = "6" Then
			ParameterToSubstitute = Parameter6;
		ElsIf CharAfterPercentage = "7" Then
			ParameterToSubstitute = Parameter7
		ElsIf CharAfterPercentage = "8" Then
			ParameterToSubstitute = Parameter8;
		ElsIf CharAfterPercentage = "9" Then
			ParameterToSubstitute = Parameter9;
		EndIf;
		If ParameterToSubstitute = Undefined Then
			Result = Result + "%";
			SubstitutionString = Mid(SubstitutionString, Position + 1);
		Else
			Result = Result + ParameterToSubstitute;
			SubstitutionString = Mid(SubstitutionString, Position + 2);
		EndIf;
		Position = StrFind(SubstitutionString, "%");
	EndDo;
	Result = Result + SubstitutionString;
	
	Return Result;

EndFunction

Function ArraysMatch(Array1, Array2) Export
	
	If Array1.Count() <> Array2.Count() Then
		Return False;
	EndIf;
	
	For Each Item In Array1 Do
		If Array2.Find(Item) = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// Returns an array from the passed value, if the passed value is an array, then a copy of it is returned,
// if the value is a structure or a match, then all the values of the collection in the array are returned, performed recursively.
// 
// Parameters:
//  Value - Arbitrary
//  NestedOnes - Boolean - pack nested values
// 
// Returns:
//  Array of Arbitrary
// 
Function PackIntoArray(Value, NestedOnes = True) Export
	
	ArrayOfValues = New Array();
	If TypeOf(Value) = Type("Array") Then
		
		ArrayOfValues = New Array(New FixedArray(Value));
		
	ElsIf TypeOf(Value) = Type("Structure") Or TypeOf(Value) = Type("Map") Then
		
		For Each KeyAndValue In Value Do
			
			If Not ValueIsFilled(KeyAndValue.Value) Then
				Continue;
			EndIf;
			
			If NestedOnes And (
				TypeOf(KeyAndValue.Value) = Type("Array") 
				Or TypeOf(KeyAndValue.Value) = Type("Structure") 
				Or TypeOf(KeyAndValue.Value) = Type("Map")) Then
				
				PackedArray = PackIntoArray(KeyAndValue.Value);
				For Each Item In PackedArray Do
					ArrayOfValues.Add(Item);
				EndDo;
				
			Else
				ArrayOfValues.Add(KeyAndValue.Value);
				
			EndIf;
			
		EndDo;
		
	Else
		
		If ValueIsFilled(Value) Then
			ArrayOfValues.Add(Value);
		EndIf;
		
	EndIf;
	
	Return ArrayOfValues;
	
EndFunction

#Region Data

// Supplements the receiver value table with data from the source value table.
// The types of table Values, tree Values, and table Parts are not available on the client.
//
// Parameters:
//  SourceTable1 - ValueTable
//                  - ValueTree
//                  - TabularSection
//                  - FormDataCollection - the table from which
//                    the rows will be taken to fill in;
//  DestinationTable - ValueTable
//                  - ValueTree
//                  - TabularSection
//                  - FormDataCollection - the table to which
//                    the rows from the source table will be added.
//
Procedure SupplementTable(SourceTable1, DestinationTable) Export
	
	For Each SourceTableRow In SourceTable1 Do
		
		FillPropertyValues(DestinationTable.Add(), SourceTableRow);
		
	EndDo;
	
EndProcedure

// Complements the table of values with values from the array Array.
//
// Parameters:
//  Table - ValueTable - table to fill in with values from the array;
//  Array  - Array - array of values to fill in the table;
//  FieldName - String - name of the value table field to load values from the array into.
// 
Procedure SupplementTableFromArray(Table, Array, FieldName) Export

	For Each Value In Array Do
		
		Table.Add()[FieldName] = Value;
		
	EndDo;
	
EndProcedure

// Complements the array array Receiver with values from the array array Source.
//
// Parameters:
//  DestinationArray - Array - array to add values to.
//  SourceArray1 - Array - array of values to fill in.
//  UniqueValuesOnly - Boolean - if true, only unique values will be included in the array.
//
Procedure SupplementArray(DestinationArray, SourceArray1, UniqueValuesOnly = False) Export
	
	If UniqueValuesOnly Then
		
		UniqueValues = New Map;
		
		For Each Value In DestinationArray Do
			UniqueValues.Insert(Value, True);
		EndDo;
		
		For Each Value In SourceArray1 Do
			If UniqueValues[Value] = Undefined Then
				DestinationArray.Add(Value);
				UniqueValues.Insert(Value, True);
			EndIf;
		EndDo;
		
	Else
		
		For Each Value In SourceArray1 Do
			DestinationArray.Add(Value);
		EndDo;
		
	EndIf;
	
EndProcedure

// Complements the structure with values from another structure.
//
// Parameters:
//   Receiver - Structure - a collection to add new values to.
//   Source - Structure - a collection from which the Key and Value pairs to fill will be read.
//   Replace - Boolean
//            - Undefined - what to do at the intersection of the source and receiver keys:
//                             True - replace receiver values (the fastest way),
//                             False - do not replace receiver values (skip),
//                             Undefined is the default value. Throwing an exception.
//
Procedure SupplementStructure(Receiver, Source, Replace = Undefined) Export
	
	For Each Item In Source Do
		If Replace <> True And Receiver.Property(Item.Key) Then
			If Replace = False Then
				Continue;
			Else
				Raise StrTemplate(
					NStr("vi = 'Giao nhau giữa khóa nguồn và đích: ""%1"".';
						|ru = 'Пересечение ключей источника и приемника: ""%1"".';
						|en = 'The source and destination have identical keys: ""%1"".'; fa = 'The source and destination have identical keys: ""%1"".';
						|it = 'Sovrapposizione delle chiavi dell''origine e della destinazione: ""%1"".';
						|pl = 'Przecięcie kluczy źródła i odbiornika: ""%1"".';
						|tr = 'Kaynak ve alıcı anahtarlarının kesişimi: ""%1""'"), 
					Item.Key);
			EndIf
		EndIf;
		Receiver.Insert(Item.Key, Item.Value);
	EndDo;
	
EndProcedure

// Complements the match with values from another match.
//
// Parameters:
//   Receiver - Map - a collection to add new values to.
//   Source - Map of KeyAndValue - a collection from which the Key and Value pairs to fill will be read.
//   Replace - Boolean
//            - Undefined - what to do at the intersection of the source and receiver keys:
//                             True - replace receiver values (the fastest way),
//                             False - do not replace receiver values (skip),
//                             Undefined is the default value. Throwing an exception.
//
Procedure SupplementMap(Receiver, Source, Replace = Undefined) Export
	
	For Each Item In Source Do
		If Replace <> True And Receiver[Item.Key] <> Undefined Then
			If Replace = False Then
				Continue;
			Else
				Raise StrTemplate(
					NStr("vi = 'Giao nhau giữa khóa nguồn và đích: ""%1"".';
						|ru = 'Пересечение ключей источника и приемника: ""%1"".';
						|en = 'The source and destination have identical keys: ""%1"".'; fa = 'The source and destination have identical keys: ""%1"".';
						|it = 'Sovrapposizione delle chiavi dell''origine e della destinazione: ""%1"".';
						|pl = 'Przecięcie kluczy źródła i odbiornika: ""%1"".';
						|tr = 'Kaynak ve alıcı anahtarlarının kesişimi: ""%1""'"), Item.Key);
			EndIf
		EndIf;
		Receiver.Insert(Item.Key, Item.Value);
	EndDo;
	
EndProcedure

#EndRegion    

#Region DynamicList

////////////////////////////////////////////////////////////////////////////////
// Functions for working with selections and parameters of dynamic lists.
//

// Find a selection element or group by the specified field name or view.
//
// Parameters:
//  SearchArea - DataCompositionFilter
//                - DataCompositionFilterItemGroup    - a container with selection items and groups,
//                                                             such as a List.Selection or group in the selection.
//  FieldName       - String - name of the layout field (not used for groups).
//  Presentation - String - view of the layout field.
//
// Returns:
//  Array - collection of selections.
//
Function FindFilterItemsAndGroups(Val SearchArea,
									Val FieldName = Undefined,
									Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemArray, SearchMethod, SearchValue);
	
	Return ItemArray;
	
EndFunction

// Add a layout element to the layout element container.
//
// Parameters:
//  AreaToAddTo - DataCompositionFilter
//                    - DataCompositionFilterItemGroup - a container with selection elements and groups,
//                                                              such as a List.Selection or group in the selection.
//  FieldName                 - String - name of the data layout field (always filled in).
//  Var_ComparisonType            - DataCompositionComparisonType - type of comparison.
//  RightValue          - Arbitrary - compare value.
//  Presentation           - String - representation of the data layout element.
//  Use           - Boolean - using the element.
//  ViewMode        - DataCompositionSettingsItemViewMode - display mode.
//  UserSettingID - String
// Returns:
//  DataCompositionFilterItem - the layout element.
//
Function AddCompositionItem(AreaToAddTo,
									Val FieldName,
									Val Var_ComparisonType,
									Val RightValue = Undefined,
									Val Presentation  = Undefined,
									Val Use  = Undefined,
									Val ViewMode = Undefined,
									Val UserSettingID = Undefined) Export
	
	Item = AreaToAddTo.Items.Add(Type("DataCompositionFilterItem"));
	Item.LeftValue = New DataCompositionField(FieldName);
	Item.ComparisonType = Var_ComparisonType;
	
	If ViewMode = Undefined Then
		Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	Else
		Item.ViewMode = ViewMode;
	EndIf;
	
	If RightValue <> Undefined Then
		Item.RightValue = RightValue;
	EndIf;
	
	If Presentation <> Undefined Then
		Item.Presentation = Presentation;
	EndIf;
	
	If Use <> Undefined Then
		Item.Use = Use;
	EndIf;
	
	// Important: The ID must be
	// set at the end of the element configuration, otherwise it will be copied
	// to the user settings partially filled in.
	If UserSettingID <> Undefined Then
		Item.UserSettingID = UserSettingID;
	ElsIf Item.ViewMode <> DataCompositionSettingsItemViewMode.Inaccessible Then
		Item.UserSettingID = FieldName;
	EndIf;
	
	Return Item;
	
EndFunction

// Change the selection element with the specified field name or view.
//
// Parameters:
//  SearchArea - DataCompositionFilter
//                - DataCompositionFilterItemGroup - a container with selection items and groups,
//                                                          such as a List.Selection or group in the selection.
//  FieldName                 - String - name of the data layout field (always filled in).
//  Presentation           - String - representation of the data layout element.
//  RightValue          - Arbitrary - compare value.
//  Var_ComparisonType            - DataCompositionComparisonType - type of comparison.
//  Use           - Boolean - using the element.
//  ViewMode        - DataCompositionSettingsItemViewMode - display mode.
//  UserSettingID - String 
//
// Returns:
//  Number - the number of modified elements.
//
Function ChangeFilterItems(SearchArea,
								Val FieldName = Undefined,
								Val Presentation = Undefined,
								Val RightValue = Undefined,
								Val Var_ComparisonType = Undefined,
								Val Use = Undefined,
								Val ViewMode = Undefined,
								Val UserSettingID = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemArray, SearchMethod, SearchValue);
	
	For Each Item In ItemArray Do
		If FieldName <> Undefined Then
			Item.LeftValue = New DataCompositionField(FieldName);
		EndIf;
		If Presentation <> Undefined Then
			Item.Presentation = Presentation;
		EndIf;
		If Use <> Undefined Then
			Item.Use = Use;
		EndIf;
		If Var_ComparisonType <> Undefined Then
			Item.ComparisonType = Var_ComparisonType;
		EndIf;
		If RightValue <> Undefined Then
			Item.RightValue = RightValue;
		EndIf;
		If ViewMode <> Undefined Then
			Item.ViewMode = ViewMode;
		EndIf;
		If UserSettingID <> Undefined Then
			Item.UserSettingID = UserSettingID;
		EndIf;
	EndDo;
	
	Return ItemArray.Count();
	
EndFunction

// Delete selection items with the specified field name or view.
//
// Parameters:
//  AreaToDelete - DataCompositionFilterItemCollection - a container with selection elements and groups,
//                                                               such as a List.Selection or group in the selection..
//  FieldName         - String - name of the layout field (not used for groups).
//  Presentation   - String - view of the layout field.
//
Procedure DeleteFilterItems(Val AreaToDelete, Val FieldName = Undefined, Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array; // Array of DataCompositionFilterItem, DataCompositionFilterItemGroup
	
	FindRecursively(AreaToDelete.Items, ItemArray, SearchMethod, SearchValue);
	
	For Each Item In ItemArray Do
		If Item.Parent = Undefined Then
			AreaToDelete.Items.Delete(Item);
		Else
			Item.Parent.Items.Delete(Item);
		EndIf;
	EndDo;
	
EndProcedure

// Add or replace an existing selection element.
//
// Parameters:
//  WhereToAdd - DataCompositionFilter
//                          - DataCompositionFilterItemGroup - a container with selection elements and groups,
//                                     such as a List.Selection or group in the selection.
//  FieldName                 - String - name of the data layout field (always filled in).
//  RightValue          - Arbitrary - compare value.
//  Var_ComparisonType            - DataCompositionComparisonType - type of comparison.
//  Presentation           - String - representation of the data layout element.
//  Use           - Boolean - using the element.
//  ViewMode        - DataCompositionSettingsItemViewMode - display mode.
//  UserSettingID - String
//
Procedure SetFilterItem(WhereToAdd,
								Val FieldName,
								Val RightValue = Undefined,
								Val Var_ComparisonType = Undefined,
								Val Presentation = Undefined,
								Val Use = Undefined,
								Val ViewMode = Undefined,
								Val UserSettingID = Undefined) Export
	
	ModifiedCount = ChangeFilterItems(WhereToAdd, FieldName, Presentation,
		RightValue, Var_ComparisonType, Use, ViewMode, UserSettingID);
	
	If ModifiedCount = 0 Then
		If Var_ComparisonType = Undefined Then
			If TypeOf(RightValue) = Type("Array")
				Or TypeOf(RightValue) = Type("FixedArray")
				Or TypeOf(RightValue) = Type("ValueList") Then
				Var_ComparisonType = DataCompositionComparisonType.InList;
			Else
				Var_ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
		EndIf;
		If ViewMode = Undefined Then
			ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
		AddCompositionItem(WhereToAdd, FieldName, Var_ComparisonType,
			RightValue, Presentation, Use, ViewMode, UserSettingID);
	EndIf;
	
EndProcedure

// Add or replace an existing selection element in the dynamic list.
//
// Parameters:
//   DynamicList - DynamicList - the list where you want to set the selection.
//   FieldName            - String - the field on which you want to set the selection.
//   RightValue     - Arbitrary - the value of the selection.
//       Optional. The default value is Undefined.
//       Attention! If the value is Undefined, the value will not be changed.
//   Var_ComparisonType  - DataCompositionComparisonType - selection condition.
//   Presentation - String - representation of the data layout element.
//       Optional. The default value is Undefined.
//       If specified, only the use flag with the specified view is displayed (the value is not displayed).
//       To clear it (so that the value is output again), pass an empty string.
//   Use - Boolean - check box for using this selection.
//       Optional. Default value: Undefined.
//   ViewMode - DataCompositionSettingsItemViewMode - the way to display this selection
//                                                                          to the user:
//        The mode of display of the elements of the structure of the components of the data.Quickstep - in the Quick settings group above the list.
//        The mode of display of the elements of the structure of the components of the data.The usual one goes to the list settings (in the More submenu).
//        The mode of display of the elements of the structure of the components of the data.Unavailable - prevent the user from changing this selection.
//   UserSettingID - String - unique ID of this selection.
//       Used for communication with user settings.
//
Procedure SetDynamicListFilterItem(DynamicList, FieldName,
	RightValue = Undefined,
	Var_ComparisonType = Undefined,
	Presentation = Undefined,
	Use = Undefined,
	ViewMode = Undefined,
	UserSettingID = Undefined) Export
	
	If ViewMode = Undefined Then
		ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	
	If ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
		DynamicListFilter = DynamicList.SettingsComposer.FixedSettings.Filter;
	Else
		DynamicListFilter = DynamicList.SettingsComposer.Settings.Filter;
	EndIf;
	
	SetFilterItem(
		DynamicListFilter,
		FieldName,
		RightValue,
		Var_ComparisonType,
		Presentation,
		Use,
		ViewMode,
		UserSettingID);
	
EndProcedure

// Delete a dynamic list selection group item.
//
// Parameters:
//  DynamicList - DynamicList - details of the form to set the selection for.
//  FieldName         - String - name of the layout field (not used for groups).
//  Presentation   - String - view of the layout field.
//
Procedure DeleteDynamicListFilterGroupItems(DynamicList, FieldName = Undefined, Presentation = Undefined) Export
	
	DeleteFilterItems(
		DynamicList.SettingsComposer.FixedSettings.Filter,
		FieldName,
		Presentation);
	
	DeleteFilterItems(
		DynamicList.SettingsComposer.Settings.Filter,
		FieldName,
		Presentation);
	
EndProcedure

// To install or update the value of the parameter ParameterName dynamic list.
//
// Parameters:
//  List          - DynamicList - the requisite forms for which you want to set the parameter.
//  ParameterName    - String             - name of the dynamic list parameter.
//  Value        - Arbitrary        - new parameter value.
//  Use   - Boolean             - indicates whether the parameter is being used.
//
Procedure SetDynamicListParameter(List, ParameterName, Value, Use = True) Export
	
	DataCompositionParameterValue = List.Parameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	If DataCompositionParameterValue <> Undefined Then
		If Use And DataCompositionParameterValue.Value <> Value Then
			DataCompositionParameterValue.Value = Value;
		EndIf;
		If DataCompositionParameterValue.Use <> Use Then
			DataCompositionParameterValue.Use = Use;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FindRecursively(ItemsCollection, ItemArray, SearchMethod, SearchValue)
	
	For Each FilterElement In ItemsCollection Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			
			If SearchMethod = 1 Then
				If FilterElement.LeftValue = SearchValue Then
					ItemArray.Add(FilterElement);
				EndIf;
			ElsIf SearchMethod = 2 Then
				If FilterElement.Presentation = SearchValue Then
					ItemArray.Add(FilterElement);
				EndIf;
			EndIf;
		Else
			
			FindRecursively(FilterElement.Items, ItemArray, SearchMethod, SearchValue);
			
			If SearchMethod = 2 And FilterElement.Presentation = SearchValue Then
				ItemArray.Add(FilterElement);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
