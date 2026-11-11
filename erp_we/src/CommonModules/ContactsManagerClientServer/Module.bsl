///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates a string presentation of a phone number.
//
// Parameters:
//    CountryCode     - String - country code.
//    CityCode     - String - area code.
//    PhoneNumber - String - phone number.
//    PhoneExtension    - String - extension.
//    Comment   - String - comment.
//
// Returns:
//   - String - a phone presentation.
//
Function GeneratePhonePresentation(CountryCode, CityCode, PhoneNumber, PhoneExtension, Comment) Export
	
	Presentation = TrimAll(CountryCode);
	If Not IsBlankString(Presentation) And Not StrStartsWith(Presentation, "+") Then
		Presentation = "+" + Presentation;
	EndIf;
	
	If Not IsBlankString(CityCode) Then
		Presentation = Presentation + ?(IsBlankString(Presentation), "", " ") + "(" + TrimAll(CityCode) + ")";
	EndIf;
	
	If Not IsBlankString(PhoneNumber) Then
		Presentation = Presentation + ?(IsBlankString(Presentation), "", " ") + TrimAll(PhoneNumber);
	EndIf;
	
	If Not IsBlankString(PhoneExtension) Then
		Presentation = Presentation + ?(IsBlankString(Presentation), "", ", ") + NStr("vi = 'máy lẻ';
																						|ru = 'доб.';
																						|en = 'ext.'; fa = 'ext.';
																						|it = 'agg.';
																						|pl = 'dod.';
																						|tr = 'ekl.'") + " " + TrimAll(PhoneExtension);
	EndIf;
	
	If Not IsBlankString(Comment) Then
		Presentation = Presentation + ?(IsBlankString(Presentation), "", ", ") + TrimAll(Comment);
	EndIf;
	
	Return Presentation;
	
EndFunction

// Returns a flag indicating whether a contact information data string is in XML format.
//
// Parameters:
//     Text - String - a string to check.
//
// Returns:
//     Boolean - check result.
//
Function IsXMLContactInformation(Val Text) Export
	
	Return TypeOf(Text) = Type("String") And StrStartsWith(TrimL(Text), "<");
	
EndFunction

// Returns a flag indicating whether a contact information data string is in JSON format.
//
// Parameters:
//     Text - String - a string to check.
//
// Returns:
//     Boolean - check result.
//
Function IsJSONContactInformation(Val Text) Export
	
	Return TypeOf(Text) = Type("String") And StrStartsWith(TrimL(Text), "{");
	
EndFunction

// Text that is displayed in the contact information field when contact information is empty and displayed as
// a hyperlink.
// 
// Returns:
//  String - a text that is displayed in the contact information field.
//
Function BlankAddressTextAsHyperlink() Export
	Return NStr("vi = 'Điền';
				|ru = 'Заполнить';
				|en = 'Fill'; fa = 'پرکردن';
				|it = 'Compilare';
				|pl = 'Fill';
				|tr = 'Doldur'");
EndFunction

// Determines whether information is entered in the contact information field when it is displayed as a hyperlink.
//
// Parameters:
//  Value - String - a contact information value.
// 
// Returns:
//  Boolean  - if True, the contact information field is filled in.
//
Function ContactsFilledIn(Value) Export
	Return TrimAll(Value) <> BlankAddressTextAsHyperlink();
EndFunction

// Returns the full description (the type and the name) of an address object.
// The output format depends on the passed parameters: the prefix usage and the order of type and name.
// 
// Parameters:
//  Address - Structure - Address broken down by fields
//  FieldName - String - Address field name
//  TypePrefix - String - The type prefix in case the address consists of two fields. For example, "ave." in "Maple ave."
//                         If the field name is set to "Number", the address is not concatenated.
//                         Instead, the function uses the original name. For example, "PremiseType".
//  reverseorder - Boolean - If set to "True", the address object type comes before the address. For example, "ave. Maple".
// 
// Returns:
//  String - The generated description of the address object.
//
Function AddressObjectName(Address, FieldName, TypePrefix = "", reverseorder = False) Export
	
	If IsBlankString(TypePrefix) Then
		Return TrimAll(Address[FieldName]);
	EndIf;
	
	FieldNameWithPrefix = ?(FieldName = "Number", TypePrefix, FieldName + TypePrefix);
	
	If reverseorder Then
		Return TrimAll(Address[FieldNameWithPrefix] +  " " + Address[FieldName]);
	EndIf;
	
	Return TrimAll(Address[FieldName] +  " " + Address[FieldNameWithPrefix]);
	
EndFunction


#Region ObsoleteProceduresAndFunctions

// Deprecated. Obsolete. Use ContactsManager.ContactInformationPresentation instead
// Generates a presentation with the specified kind for the address input form.
//
// Parameters:
//    AddressStructure1  - Structure - an address as a structure.
//                                   See structure details in the AddressManager.AddressInfo function.
//                                   See details of the previous structure version in the AddressManager.PreviousContactInformationXMLStructure function.
//    Presentation    - String    - address presentation.
//    KindDescription - String    - a kind description.
//
// Returns:
//    String - an address presentation with kind.
//
Function GenerateAddressPresentation(AddressStructure1, Presentation, KindDescription = Undefined) Export
	
	Presentation = "";
	
	If TypeOf(AddressStructure1) <> Type("Structure") Then
		Return Presentation;
	EndIf;
	
	AddShortForms = AddressStructure1.Property("County");
	
	If AddressStructure1.Property("Country") Then
		Presentation = AddressStructure1.Country;
	EndIf;
	
	AddressPresentationByStructure(AddressStructure1, "IndexOf", Presentation);
	AddressPresentationByStructure(AddressStructure1, "State", Presentation, "AreaAbbr", AddShortForms);
	AddressPresentationByStructure(AddressStructure1, "County", Presentation, "CountyAbbr", AddShortForms);
	AddressPresentationByStructure(AddressStructure1, "District", Presentation, "DistrictAbbr", AddShortForms);
	AddressPresentationByStructure(AddressStructure1, "City", Presentation, "CityAbbr", AddShortForms);
	AddressPresentationByStructure(AddressStructure1, "Locality", Presentation, "LocalityAbbr", AddShortForms);
	AddressPresentationByStructure(AddressStructure1, "Territory", Presentation, "TerritoryAbbr", AddShortForms);
	AddressPresentationByStructure(AddressStructure1, "Street", Presentation, "StreetShortForm", AddShortForms);
	AddressPresentationByStructure(AddressStructure1, "AdditionalTerritory", Presentation, "AdditionalTerritoryAbbr", AddShortForms);
	AddressPresentationByStructure(AddressStructure1, "AdditionalTerritoryItem", Presentation, "AdditionalTerritoryItemAbbr", AddShortForms);
	
	If AddressStructure1.Property("BuildingUnit") Then
		SupplementAddressPresentation(TrimAll(ValueByStructureKey("Number", AddressStructure1.BuildingUnit)), ", " + ValueByStructureKey("BuildingType", AddressStructure1.BuildingUnit) + " ", Presentation);
	Else
		SupplementAddressPresentation(TrimAll(ValueByStructureKey("House", AddressStructure1)), ", " + ValueByStructureKey("HouseType", AddressStructure1) + " ", Presentation);
	EndIf;
	
	If AddressStructure1.Property("BuildingUnits") Then
		For Each Building In AddressStructure1.BuildingUnits Do
			SupplementAddressPresentation(TrimAll(ValueByStructureKey("Number", Building )), ", " + ValueByStructureKey("BuildingUnitType", Building)+ " ", Presentation);
		EndDo;
	Else
		SupplementAddressPresentation(TrimAll(ValueByStructureKey("Building", AddressStructure1)), ", " + ValueByStructureKey("BuildingUnitType", AddressStructure1)+ " ", Presentation);
	EndIf;
	
	If AddressStructure1.Property("Premises") Then
		For Each Premise In AddressStructure1.Premises Do
			SupplementAddressPresentation(TrimAll(ValueByStructureKey("Number", Premise)), ", " + ValueByStructureKey("PremiseType", Premise)+ " ", Presentation);
		EndDo;
	Else
		SupplementAddressPresentation(TrimAll(ValueByStructureKey("Appartment", AddressStructure1)), ", " + ValueByStructureKey("ApartmentType", AddressStructure1) + " ", Presentation);
	EndIf;
	
	KindDescription = ValueByStructureKey("KindDescription", AddressStructure1);
	PresentationWithKind = KindDescription + ": " + Presentation;
	
	Return PresentationWithKind;
	
EndFunction

// Deprecated. Obsolete. To get an address, use AddressManager.AddressInfo instead.
// To get a phone or fax structure, use ContactsManager.PhoneInfo instead.
// Returns contact information structure by type.
//
// Parameters:
//  CIType - EnumRef.ContactInformationTypes - contact information type.
//  AddressFormat - String - not used, left for backward compatibility.
// 
// Returns:
//  Structure - a blank contact information structure, keys - field names and field values.
//
Function ContactInformationStructureByType(CIType, AddressFormat = Undefined) Export
	
	If CIType = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		Return AddressFieldsStructure();
	ElsIf CIType = PredefinedValue("Enum.ContactInformationTypes.Phone") Then
		Return PhoneFieldStructure();
	Else
		Return New Structure;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Details of contact information keys for storing its values in the JSON format.
// The keys list can be extended with fields in the same-name function of the AddressManagerClientServer common module.
//
// Parameters:
//  ContactInformationType  - EnumRef.ContactInformationTypes - contact information type
//                             that determines a composition of contact information fields.
//
// Returns:
//   Structure - Contact information fields:
//     * value - String - Contact information presentation.
//     * comment - String - Comment.
//     * type - String - Contact information type. See the value in Enum.ContactInformationTypes.Address.
//     Extended composition of fields for the "Address" contact information type:
//     * country - String - Country name. For example, "Peru".
//     * countryCode - String -Country code.
//     * ZIPcode- String - postal code.
//     * area - String - State description.
//     * areaType - String - a short form (type) of "state".
//     * city - String - a city description.
//     * cityType - String - a short form (type) of "city", for example, c.
//     * street - String - Name of the street (avenue, alley, etc). It may also include the number of the house, apartment, or office.
//                         
//     * streetType - String - Short form of the street (avenue, alley, etc). For example, "st."
//     * houseNumber - String - An additional field for additional address information, 
//                              such as intercom, entrance number, or floor.
//     * admLevels - String - Fields in the order they will appear in the address presentation. For example, "ZIPcode,Area,Street".
//     * addressType - String - Address type: either a free form or structured by field.
//     The "Phone" contact information kind has an extended set of fields.:
//     * CountryCode - String - Country code.
//     * AreaCode - String - a state code.
//     * Number - String - a phone number.
//     * ExtNumber - String - an extension.
//
Function NewContactInformationDetails(Val ContactInformationType) Export
	
	If TypeOf(ContactInformationType) <> Type("EnumRef.ContactInformationTypes") Then
		ContactInformationType = "";
	EndIf;
	
	Result = New Structure;
	
	Result.Insert("version", 5);
	Result.Insert("value",   "");
	Result.Insert("comment", "");
	Result.Insert("type",    ContactInformationTypeToString(ContactInformationType));
	
	If ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		
		Result.Insert("country",     "");
		Result.Insert("addressType", CustomFormatAddress());
		Result.Insert("countryCode", "");
		Result.Insert("ZIPcode",     "");
		Result.Insert("area",        "");
		Result.Insert("areaType",    "");
		Result.Insert("city",        "");
		Result.Insert("cityType",    "");
		Result.Insert("street",      "");
		Result.Insert("streetType",  "");
		Result.Insert("houseNumber", "");
		Result.Insert("admLevels",   "");
		
	ElsIf ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.Phone")
		Or ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.Fax") Then
		
		Result.Insert("countryCode", "");
		Result.Insert("areaCode", "");
		Result.Insert("number", "");
		Result.Insert("extNumber", "");
		
	ElsIf ContactInformationType = PredefinedValue("Enum.ContactInformationTypes.WebPage") Then
		
		Result.Insert("name", "");
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  Form- ClientApplicationForm
// 
// Returns:
//  FormDataCollection:
//   *  AttributeName  - String
//   *  Kind           - CatalogRef.ContactInformationKinds
//   *  Type           - EnumRef.ContactInformationTypes
//   *  Value      - String
//   *  Presentation - String
//   *  Comment   - String
//   *  IsTabularSectionAttribute - Boolean
//   *  IsHistoricalContactInformation - Boolean
//   *  ValidFrom - Date
//   *  StoreChangeHistory - Boolean
//   *  ItemForPlacementName - String
//   *  InternationalAddressFormat - Boolean
//   *  Mask - String
//
Function DescriptionOfTheContactInformationOnTheForm(Form) Export
	Return Form.ContactInformationAdditionalAttributesDetails;
EndFunction

#EndRegion

#Region Private

// Returns:
//  Structure - Contact information details:
//    * FieldValues - String - contact information in JSON format
//    * Presentation - String - The contact information presentation. 
//                              Used in cases when the "FieldValues" parameter is missing the "Presentation" field.
//    * ContactInformationKind - EnumRef.ContactInformationTypes 
//                              - CatalogRef.ContactInformationKinds - contact information type
//
Function ContactInformationDetails(FieldValues, Presentation, ContactInformationKind) Export
	
	Result = New Structure;
	Result.Insert("FieldValues", FieldValues);
	Result.Insert("Presentation", Presentation);
	Result.Insert("ContactInformationKind", ContactInformationKind);
	
	Return Result;
	
EndFunction

// Returns a structure of address fields that will be used to generate an international address.
// If the "AddressManager" common module is integrated, call the function from this module. 
//
// Returns:
//  Structure:
//    * Presentation    - String - Text presentation of the address according to its administrative structure.
//                                  For example, "Av. Larco 1234, Miraflores 15074, Lima, Peru".
//    * AddressType        - String - Main address type. Applies only to addresses in the Russian Federation.
//                                  Valid options are "FreeForm" and "Foreign2".
//    * Country           - String - Text presentation of a country. For example, "Peru".
//    * CountryCode        - String - Country code. For example, "51".
//    * IndexOf           - String - Postal code. For example, "15074".
//    * State           - String - Text presentation of a region or state. For example, "Miraflores".
//    * City            - String - Text presentation of a city. 
//    * Street            - String - Text presentation of a street. For example, "Main".
//    * AdditionalInformation - String - Text presentation of additional information  
//                                 (such as office, floor, intercom, and other instructions).
//    * Comment - String - Comment to the address.
//
Function AddressFields() Export
	
	Result = New Structure;
	
	Result.Insert("AddressType"                 , "");
	Result.Insert("Comment"               , "");
	
	Result.Insert("Presentation"             , "");
	
	Result.Insert("Country"   , "");
	Result.Insert("CountryCode", "");
	Result.Insert("IndexOf"   , "");
	
	Result.Insert("State" , "");
	Result.Insert("District"  , "");
	Result.Insert("City"  , "");
	Result.Insert("Street"  , "");
	
	Result.Insert("AdditionalInformation", "");
	
	Return Result;
	
EndFunction

Function ContactInformationTypeToString(Val ContactInformationType)
	
	Result = New Map;
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.Address"), "Address");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.Phone"), "Phone");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.Email"), "Email");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.Skype"), "Skype");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.WebPage"), "WebPage");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.Fax"), "Fax");
	Result.Insert(PredefinedValue("Enum.ContactInformationTypes.Other"), "Other");
	Result.Insert("", "");
	Return Result[ContactInformationType];
	
EndFunction

Function IsItForeignAddressOrEAEU(AddressType) Export
	
	Return StrCompare(AddressType, EEUAddress()) = 0
	 Or StrCompare(AddressType, ForeignAddress()) = 0;
	 
EndFunction

Function CustomFormatAddress() Export
	Return "FreeForm";
EndFunction

Function EEUAddress() Export
	Return "EEU";
EndFunction

Function ForeignAddress() Export
	Return "Foreign2";
EndFunction

Function IsAddressInFreeForm(AddressType) Export
	Return StrCompare(CustomFormatAddress(), AddressType) = 0;
EndFunction

Function ConstructionOrPremiseValue(Type, Value) Export
	Return New Structure("type, number", Type, Value);
EndFunction

// Returns a blank address structure.
//
// Returns:
//    Structure - address, keys - field names and field values.
//
Function AddressFieldsStructure() Export
	
	AddressStructure1 = New Structure;
	AddressStructure1.Insert("Presentation", "");
	AddressStructure1.Insert("Country", "");
	AddressStructure1.Insert("CountryDescription", "");
	AddressStructure1.Insert("CountryCode","");
	
	Return AddressStructure1;
	
EndFunction

// Returns command details for the given contact information kind.
//
// Parameters:
//   ContactInformationParameters - Structure:
//     * GroupForPlacement - String
//     * TitleLocation - String
//     * AddedAttributes - ValueList
//     * DeferredInitialization - Boolean
//     * DeferredInitializationExecuted - Boolean
//     * AddedItems - ValueList
//     * ItemsToAddList - ValueList:
//         * Value - Structure:
//           ** Ref - CatalogRef.ContactInformationKinds
//         * Key - String
//     * CanSendSMSMessage1 - Boolean
//     * Owner - AnyRef
//     * URLProcessing - Boolean
//     * HiddenKinds - Array - Contact information kinds to be hidden from the form.
//     * DetailsOfCommands - See ContactsManager.DetailsOfCommands
//     * ShouldShowIcons - Boolean
//     * ItemsPlacedOnForm - Map of KeyAndValue - Contact information kinds that were added to the form interactively.
//                                         In case of deferred initialization, they will appear on the form after the 
//                                         ContactsManager.ExecuteDeferredInitialization procedure is called.:
//         * Key - CatalogRef.ContactInformationKinds
//         * Value - Boolean
//     * ExcludedKinds - Array - Obsolete. Instead, use "ItemsPlacedOnForm".
//     * AllowAddingFields - Boolean
//   Type - EnumRef.ContactInformationTypes
//   Kind - CatalogRef.ContactInformationKinds
//   StoreHistory - Boolean
//
// Returns:
//   See ContactsManager.CommandsOfContactInfoType
//
Function CommandsToOutputToForm(ContactInformationParameters, Type, Kind, StoreHistory) Export
	
	DetailsOfCommands = ContactInformationParameters.DetailsOfCommands;
	
	If ValueIsFilled(Kind) Then
		KindCommands = DetailsOfCommands[Kind];	
	Else
		KindCommands = Undefined;
	EndIf;

	TypeCommands = DetailsOfCommands[Type];
	
	CommandsForOutput = New Structure;
	
	If TypeCommands = Undefined Then
		Return CommandsForOutput;
	EndIf;
	
	If KindCommands = Undefined Then
		For Each TypeCommand In TypeCommands Do
			If ValueIsFilled(TypeCommand.Value.Action) Then
				CommandsForOutput.Insert(TypeCommand.Key, TypeCommand.Value);
			EndIf;
		EndDo;
	Else
		For Each TypeCommand In TypeCommands Do
			KindCommandVal = KindCommands[TypeCommand.Key];
			If KindCommandVal = Undefined Then
				If ValueIsFilled(TypeCommand.Value.Action) Then
					CommandsForOutput.Insert(TypeCommand.Key, TypeCommand.Value);
				EndIf;
			Else
				If ValueIsFilled(KindCommandVal.Action) Then
					CommandsForOutput.Insert(TypeCommand.Key, KindCommandVal);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If Type = PredefinedValue("Enum.ContactInformationTypes.Phone") Then
		If Not ContactInformationParameters.CanSendSMSMessage1 Then
			CommandsForOutput.Delete("SendSMS");
		EndIf;
	ElsIf Type = PredefinedValue("Enum.ContactInformationTypes.WebPage") Then 	
		If ContactInformationParameters.URLProcessing Then
			CommandsForOutput.Delete("OpenWebPage");
		EndIf;
	EndIf;	
	
	If Not StoreHistory And (Type = PredefinedValue("Enum.ContactInformationTypes.Address")
		Or Type = PredefinedValue("Enum.ContactInformationTypes.Phone")
		Or Type = PredefinedValue("Enum.ContactInformationTypes.Fax")) Then
		CommandsForOutput.Delete("ShowChangeHistory");	
	EndIf;
	
	Return CommandsForOutput;
	
EndFunction

// Returns a detailed prompt for the given address.
// 
// Parameters:
//  CommandsForOutput    - Structure:
//    * AddCommentToAddress - See ContactsManager.CommandProperties
//    * ShowOnGoogleMap    - See ContactsManager.CommandProperties
//    * PlanMeeting     - See ContactsManager.CommandProperties
//    * ShowChangeHistory - See ContactsManager.CommandProperties
//  AddressPresentation - String
//  Comment         - String
// 
// Returns:
//  FormattedString
//
Function ExtendedTooltipForAddress(CommandsForOutput, AddressPresentation, Comment) Export

	If CommandsForOutput.Property("AddCommentToAddress") And ValueIsFilled(AddressPresentation) Then
		ModifyComment = New FormattedString(CommandsForOutput.AddCommentToAddress.Picture, , , ,
			"AddCommentToAddress");
	Else
		ModifyComment = "";
	EndIf;
	
	ShowOnMap = "";
	For Each CommandToOutput In CommandsForOutput Do
		ActionKind = ActionKindOfContactInformationTypeCommand(CommandToOutput.Value.Action);
		If StrCompare(ActionKind, "ShowOnMap") = 0 Then
			If IsBlankString(ShowOnMap) Then
				ShowOnMap = New FormattedString(CommandToOutput.Value.Title,, WebColors.Gray,, ActionKind);
			Else
				ShowOnMap = New FormattedString(NStr("vi = 'Trên thẻ';
													|ru = 'На карте';
													|en = 'On map'; fa = 'On map';
													|it = 'На карте';
													|pl = 'On map';
													|tr = 'Haritada'"),, WebColors.Gray,, ActionKind);
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	If CommandsForOutput.Property("ShowChangeHistory") Then
		ShowHistory = New FormattedString("History", ,WebColors.Gray, , "ShowChangeHistory");
	Else
		ShowHistory = "";
	EndIf;

	If CommandsForOutput.Property("PlanMeeting") Then
		PlanMeeting = New FormattedString(CommandsForOutput.PlanMeeting.Title, ,WebColors.Gray , , "PlanMeeting");
	Else
		PlanMeeting = "";
	EndIf;          
	
	Indent = ?(ValueIsFilled(ShowHistory) And ValueIsFilled(ShowOnMap), "    ", "");
	CommandsString = New FormattedString(ShowHistory, Indent, ShowOnMap);
	
	Indent = ?(ValueIsFilled(CommandsString) And ValueIsFilled(PlanMeeting), "    ", "");
	CommandsString = New FormattedString(CommandsString, Indent, PlanMeeting);   

	If ValueIsFilled(Comment) Then
		ModifyComment = ?(ValueIsFilled(ModifyComment), ModifyComment, ""); 
		Indent = ?(ValueIsFilled(ModifyComment), " ", "");  
		IndentBeforeCommands = ?(ValueIsFilled(CommandsString), "    ", "");
		ExtendedTooltipForAddress = New FormattedString(ModifyComment, Indent, TrimAll(Comment), IndentBeforeCommands, CommandsString);
	Else
		Indent = ?(ValueIsFilled(CommandsString) And ValueIsFilled(ModifyComment), "    ", ""); 
		ExtendedTooltipForAddress = New FormattedString(ModifyComment, Indent, CommandsString);
	EndIf;    
		
	Return ExtendedTooltipForAddress;

EndFunction

Function ActionKindOfContactInformationTypeCommand(Action) Export
	
	If Action = "ContactsManagerClient.ShowAddressOnGoogleMaps" Then
		ActionKind = "ShowOnMap";
	Else
		ActionKind = "";
		ContactsManagerClientServerLocalization.OnDefineContactInfoTypeCommandActions(Action, ActionKind);
	EndIf;
	Return ActionKind;
	
EndFunction

#Region PrivateForWorkingWithXMLAddresses

// Returns structure with a description and a short form by value.
//
// Parameters:
//     Text - String - full description.
//
// Returns:
//     Structure:
//         * Description - String - a text part.
//         * Abbr   - String - a text part.
//
Function DescriptionShortForm(Val Text) Export
	Result = New Structure("Description, Abbr");
	
	Text = TrimAll(Text);
	
	TextUppercase = Upper(Text);
	If StrEndsWith(TextUppercase, "TER. HS")
		Or StrEndsWith(TextUppercase, "TER. SUBURBANNONCOMMERCIALCOMMUNITY") Then
		Result.Abbr = Right(Text, 8);
		Result.Description = Left(Text, StrLen(Text) - 9);
		Return Result;
	EndIf;
	
	Parts = DescriptionsAndShortFormsSet(Text, True);
	If Parts.Count() > 0 Then
		FillPropertyValues(Result, Parts[0]);
	Else
		Result.Description = Text;
	EndIf;
	
	Return Result;
EndFunction

Function ConnectTheNameAndTypeOfTheAddressObject(Val Description, Val AddressObjectType, TypeInEnd = False) Export
	
	Description        = TrimAll(Description);
	AddressObjectType = TrimAll(AddressObjectType);
	
	If IsBlankString(AddressObjectType) Then
		Return Description;
	EndIf;
	
	If IsBlankString(Description) Then
		Return AddressObjectType;
	EndIf;
	
	If TypeInEnd Then
		
		
		Return Description + " " + AddressObjectType;
	EndIf;
	
	Return AddressObjectType + " "+ Description;
	
EndFunction

// Splits text into words using the specified separators. Default separators are space characters.
//
// Parameters:
//     Text       - String - a string to split.
//     Separators - String - an optional string of separator characters.
//
// Returns:
//     Array - strings and words
//
Function TextWords(Val Text, Val Separators = Undefined)
	
	WordBeginning = 0;
	State   = 0;
	Result   = New Array;
	
	For Position = 1 To StrLen(Text) Do
		CurrentChar = Mid(Text, Position, 1);
		IsSeparator = ?(Separators = Undefined, IsBlankString(CurrentChar), StrFind(Separators, CurrentChar) > 0);
		
		If State = 0 And (Not IsSeparator) Then
			WordBeginning = Position;
			State   = 1;
		ElsIf State = 1 And IsSeparator Then
			Result.Add(Mid(Text, WordBeginning, Position-WordBeginning));
			State = 0;
		EndIf;
	EndDo;
	
	If State = 1 Then
		Result.Add(Mid(Text, WordBeginning, Position-WordBeginning));    
	EndIf;
	
	Return Result;
EndFunction

// Splits comma-separated text.
//
// Parameters:
//     Text              - String - a text to separate.
//     ExtractShortForms - Boolean - an optional parameter.
//
// Returns:
//     Array - contains "Description, ShortForm" structures.
//
Function DescriptionsAndShortFormsSet(Val Text, Val ExtractShortForms = True)
	
	Result = New Array;
	For Each Term In TextWords(Text, ",") Do
		PartRow = TrimAll(Term);
		If IsBlankString(PartRow) Then
			Continue;
		EndIf;
		
		Position = ?(ExtractShortForms, StrLen(PartRow), 0);
		While Position > 0 Do
			If Mid(PartRow, Position, 1) = " " Then
				Result.Add(New Structure("Description, Abbr",
					TrimAll(Left(PartRow, Position-1)), TrimAll(Mid(PartRow, Position))));
				Position = -1;
				Break;
			EndIf;
			Position = Position - 1;
		EndDo;
		If Position = 0 Then
			Result.Add(New Structure("Description, Abbr", PartRow));
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#Region OtherPrivate

// Adds a string to an address presentation.
//
// Parameters:
//    Supplement         - String - an address addition.
//    ConcatenationString - String - a concatenation string.
//    Presentation      - String - address presentation.
//
Procedure SupplementAddressPresentation(Supplement, ConcatenationString, Presentation)
	
	If Supplement <> "" Then
		Presentation = Presentation + ConcatenationString + Supplement;
	EndIf;
	
EndProcedure

// Returns a value string by structure property.
// 
// Parameters:
//    Var_Key - String - a structure key.
//    Structure - Structure - a structure to pass.
//
// Returns:
//    Arbitrary - value.
//    String       - a blank string if there is no value.
//
Function ValueByStructureKey(Var_Key, Structure)
	
	Value = Undefined;
	
	If Structure.Property(Var_Key, Value) Then 
		Return String(Value);
	EndIf;
	
	Return "";
	
EndFunction

Procedure AddressPresentationByStructure(AddressStructure1, DescriptionKey, Presentation, ShortFormKey = "", AddShortForms = False, ConcatenationString = ", ")
	
	If AddressStructure1.Property(DescriptionKey) Then
		Supplement = TrimAll(AddressStructure1[DescriptionKey]);
		If ValueIsFilled(Supplement) Then
			If AddShortForms And AddressStructure1.Property(ShortFormKey) Then
				Supplement = Supplement + " " + TrimAll(AddressStructure1[ShortFormKey]);
			EndIf;
			If ValueIsFilled(Presentation) Then
				Presentation = Presentation + ConcatenationString + Supplement;
			Else
				Presentation = Supplement;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// Returns a blank phone structure.
//
// Returns:
//    Structure - keys - field names and field values.
//
Function PhoneFieldStructure() Export
	
	PhoneStructure = New Structure;
	PhoneStructure.Insert("Presentation", "");
	PhoneStructure.Insert("CountryCode", "");
	PhoneStructure.Insert("CityCode", "");
	PhoneStructure.Insert("PhoneNumber", "");
	PhoneStructure.Insert("PhoneExtension", "");
	PhoneStructure.Insert("Comment", "");
	
	Return PhoneStructure;
	
EndFunction

Function WebsiteAddress(Val Presentation, Val Ref, ReadOnly) Export
	
	If IsBlankString(Presentation) Or IsBlankString(Ref)  Then
		Presentation = BlankAddressTextAsHyperlink();
		Ref = WebsiteURL();
	EndIf;
	
	If StrCompare(Presentation, BlankAddressTextAsHyperlink()) = 0 And ReadOnly Then
		Return Presentation;
	EndIf;
	
	PresentationText = New FormattedString(Presentation,,,, Ref);
	
	If ReadOnly Then
		Return PresentationText;
	EndIf;
	
	PictureChange = New FormattedString(PictureLib.EditWebsiteAddress,,,, WebsiteURL());
	Return New FormattedString(PresentationText, "  ", PictureChange);

EndFunction

Function WebsiteURL() Export
	Return "e1cib/app/DataProcessor.ContactInformationInput.Form.Website";
EndFunction



// Returns a list of filling errors as a value list:
//
// Parameters:
//  InfoAboutPhone  - See PhoneFieldStructure
//  AdditionalChecksModule - Arbitrary
// 
// Returns:
//  ValueList - Phone number entry errors:
//    * Presentation   - Error details.
//    * Value        - XPath for the field.
//
Function PhoneFillingErrors(InfoAboutPhone, AdditionalChecksModule = Undefined) Export
	
	ErrorList = New ValueList;
	FullPhoneNumber = InfoAboutPhone.CountryCode + InfoAboutPhone.CityCode + InfoAboutPhone.PhoneNumber;
	
	CountryCodeNumbersOnly = LeaveOnlyTheNumbersInTheLine(InfoAboutPhone.CountryCode);
	If ValueIsFilled(InfoAboutPhone.CountryCode) And IsBlankString(CountryCodeNumbersOnly) Then
		ErrorList.Add("CountryCode", NStr("vi = 'Mã quốc gia có chứa các ký tự không hợp lệ';
											|ru = 'Код страны содержит недопустимые символы';
											|en = 'Country code contains invalid characters'; fa = 'Country code contains invalid characters';
											|it = 'Il codice paese contiene caratteri non ammessi';
											|pl = 'Kod kraju zawiera niedopuszczalne znaki';
											|tr = 'Ülke kodu geçersiz karakterler içeriyor'"));
	EndIf;
	
	PhoneNumberNumbersOnly = LeaveOnlyTheNumbersInTheLine(InfoAboutPhone.Presentation);
	If IsBlankString(PhoneNumberNumbersOnly) Then
		ErrorList.Add("PhoneNumber", NStr("vi = 'Số điện thoại không chứa số';
											|ru = 'Номер телефона не содержит цифр';
											|en = 'Phone number does not contain digits'; fa = 'Phone number does not contain digits';
											|it = 'Il numero di telefono non contiene cifre';
											|pl = 'Numer telefonu nie zawiera cyfr';
											|tr = 'Telefon numarası rakamları içermiyor'"));
	EndIf;

	FullPhoneNumberOnlyDigits = LeaveOnlyTheNumbersInTheLine(FullPhoneNumber);
	If StrLen(FullPhoneNumberOnlyDigits) > 15 Then
		ErrorList.Add("PhoneNumber", NStr("vi = 'Số điện thoại quá dài';
											|ru = 'Номер телефона слишком длинный';
											|en = 'Phone number is too long.'; fa = 'Phone number is too long.';
											|it = 'Il numero di telefono risulta troppo lungo';
											|pl = 'Zbyt długi numer telefonu';
											|tr = 'Telefon numarası çok uzun'"));
	EndIf;
	
	If ValueIsFilled(InfoAboutPhone.CountryCode) And PhoneNumberContainsProhibitedChars(InfoAboutPhone.CountryCode) Then
		ErrorList.Add("CountryCode", NStr("vi = 'Mã quốc gia có chứa các ký tự không hợp lệ';
											|ru = 'Код страны содержит недопустимые символы';
											|en = 'Country code contains invalid characters'; fa = 'Country code contains invalid characters';
											|it = 'Il codice paese contiene caratteri non ammessi';
											|pl = 'Kod kraju zawiera niedopuszczalne znaki';
											|tr = 'Ülke kodu geçersiz karakterler içeriyor'"));
	EndIf;
	
	If ValueIsFilled(InfoAboutPhone.CityCode) And PhoneNumberContainsProhibitedChars(InfoAboutPhone.CityCode) Then
		ErrorList.Add("CityCode", NStr("vi = 'Mã thành phố có chứa các ký tự không hợp lệ';
										|ru = 'Код города содержит недопустимые символы';
										|en = 'City code contains invalid characters'; fa = 'City code contains invalid characters';
										|it = 'Il codice della città contiene caratteri non ammessi';
										|pl = 'Kod miasta zawiera niedopuszczalne znaki';
										|tr = 'Şehir kodu geçersiz karakterler içeriyor'"));
	EndIf;
	
	If ValueIsFilled(InfoAboutPhone.PhoneNumber) And PhoneNumberContainsProhibitedChars(InfoAboutPhone.PhoneNumber) Then
		ErrorList.Add("PhoneNumber", NStr("vi = 'Số điện thoại có chứa các ký tự không hợp lệ';
											|ru = 'Номер телефона содержит недопустимые символы';
											|en = 'Phone number contains illegal characters.'; fa = 'Phone number contains illegal characters.';
											|it = 'Il numero di telefono contiene i simboli non ammissibili';
											|pl = 'Numer telefonu zawiera nieprawidłowe znaki.';
											|tr = 'Telefon numarası uygunsuz karakterleri içeriyor'"));
	EndIf;
	
	If AdditionalChecksModule <> Undefined Then
		AdditionalChecksModule.CheckCorrectnessOfCountryAndCityCodes(InfoAboutPhone, ErrorList);
	EndIf;
	
	Return ErrorList;
	
EndFunction

Function LeaveOnlyTheNumbersInTheLine(Val String) Export
	
	ExcessCharacters = StrConcat(StrSplit(String, "0123456789"), "");
	Result     = StrConcat(StrSplit(String, ExcessCharacters), "");
	
	Return Result;
	
EndFunction

// Checks whether the string contains only ~
//
// Parameters:
//  CheckString          - String - a string to check.
//
// Returns:
//   Boolean - True - the string contains only numbers or is empty, False - the string contains other characters.
//
Function PhoneNumberContainsProhibitedChars(Val CheckString)
	
	AllowedCharactersList = "+-.,() wp1234567890";
	Return StrSplit(CheckString, AllowedCharactersList, False).Count() > 0;
	
EndFunction

#EndRegion

#EndRegion

