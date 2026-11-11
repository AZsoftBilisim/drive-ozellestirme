///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the details of the commands associated with the passed contact information type.
// Intended for ContactsManagerOverridable.OnDefineSettings.
// TypeCommands - Output parameter.
// 
// Parameters:
//  TypeCommands - Structure:
//   * Key - String - Command name. For example, "ShowOnMap".
//   * Value - See ContactsManager.CommandProperties
//  Type - EnumRef.ContactInformationTypes - contact information type.
//
Procedure OnDefineContactInfoTypeCommands(TypeCommands, Type) Export
	
	
EndProcedure

// Converts contact information from JSON into XML.
//
// Parameters:
//  ContactInformationInJSON - String - contact information in the internal JSON format.
//  ContactInformationToXML  - String - Output parameter. Contact information converted into XML.
//  ExpectedType              - EnumRef.ContactInformationTypes - Determines the data type if it cannot be 
//                              determined from the JSON data.
//
Procedure OnConvertContactInformationFromJSONToXML(Val ContactInformationInJSON, ContactInformationToXML, ExpectedType = Undefined) Export
	
	
EndProcedure

// Called when converting contact information from XML into XDTO.
// 
// Parameters:
//  Text - String - Contact information in XML format.
//  ContactInformation - XDTODataObject -  Output parameter. Contact information converted into XDTO.
//  ExpectedKind - EnumRef.ContactInformationTypes - Expected contact information kind.
//  ConversionResult - Structure:
//    * InfoCorrected - Boolean - True if the information is valid. 
//                          - Undefined - Not converted.
//  SettingsOfConversion - See ContactsManager.ContactInformationConversionSettings
//
Procedure OnConvertContactInformationFromXML(Val Text, ContactInformation, Val ExpectedKind = Undefined, ConversionResult = Undefined, SettingsOfConversion = Undefined) Export
	
	
EndProcedure

// Called when contact information is converted into JSON.
// 
// Parameters:
//  ContactInformation - String - Contact information in XML format.
//  JSONContactInformation - String -  Output parameter. Contact information converted into JSON.
//  Type - EnumRef.ContactInformationTypes - Expected contact information kind.
//  SettingsOfConversion - Structure
//
Procedure OnConvertContactInformationToJSONStructure(ContactInformation, JSONContactInformation, Type, SettingsOfConversion) Export
	
	
EndProcedure

// Converts input contact information into XML.
// 
// Parameters:
//  Data - See ContactsManagerClientServer.ContactInformationDetails
//  Result - See ContactsManager.ContactInfoFieldsToConvert 
//  StandardProcessing - Boolean - Output parameter. Set to "False" if a custom procedure is implemented.
// 
Procedure OnConvertContactInfoToXML(Val Data, Result, StandardProcessing) Export
	
	
EndProcedure

// Converts contact information that includes a phone number into an XDTO object.
// 
// Parameters:
//  FieldValues - String - Contact information
//  Result - XDTODataObject - Output parameter. Contact information converted into XDTO.
//  Presentation - String - Contact information presentation
//  ExpectedType - EnumRef.ContactInformationTypes - Contact information type
// 
Procedure OnConvertPhoneToXDTOObject(FieldValues, Result, Presentation = "", ExpectedType = Undefined) Export
	
	
EndProcedure

// Converts contact information that includes a fax number into an XDTO object.
// 
// Parameters:
//  FieldValues - String - Contact information
//  Result - XDTODataObject - Output parameter. Contact information converted into XDTO.
//  Presentation - String - Contact information presentation
//  ExpectedType - EnumRef.ContactInformationTypes - Contact information type
// 
Procedure OnConvertFaxToXDTOObject(FieldValues, Result, Presentation = "", ExpectedType = Undefined) Export
	
	
EndProcedure

// Adds a comment to contact information.
// 
// Parameters:
//  ContactInformation - String - Contact information the comment should be added to.
//  Comment - String - A comment. 
// 
Procedure OnSetContactInformationComment(ContactInformation, Val Comment) Export
	
	
EndProcedure

// Determines the type of the contact information. 
//
// Parameters:
//  XMLString - String - contact information in XML format.
//  Type - EnumRef.ContactInformationTypes - Output parameter. The contact information type.
//
Procedure OnDefineContactInformationType(Val XMLString, Type) Export
EndProcedure

// Called when converting a contact information presentation into XDTO.
// 
// Parameters:
//  Text - String - a contact information presentation.
//  Result - XDTODataObject - Output parameter. The conversion result.
//  ExpectedKind - EnumRef.ContactInformationTypes - contact information type.
//
Procedure OnConvertXDTOContactInformationByPresentation(Text, Result, ExpectedKind) Export
	
	
EndProcedure

// Converts contact information from XDTO into XML.
// 
// Parameters:
//  XDTOInformationObject - XDTODataObject - Contact information converted into XDTO.
//  ContactInformationToXML - String - Output parameter. Contact information converted into XML.
//
Procedure OnConvertXDTOContactInformationToXML(XDTOInformationObject, ContactInformationToXML) Export
	
	
EndProcedure

// Called when getting a contact information row.
// 
// Parameters: 
//   XMLData - String - Contact information in XML format.
//   CompositionRow - String -  Output parameter. A contact information row extracted from XML.
//
Procedure OnGetContactInformationCompositionString(XMLData, CompositionRow) Export
	
	
EndProcedure

// Called when populating table attributes for a web page.
// 
// Parameters:
//  Source - XDTODataObject - Source of the contact information
//  Result - String - Population output.
//
Procedure OnFillTabularSectionAttributesForWebPage(Source, Result) Export
	
	
EndProcedure

// Compares two instances of contact information.
//
// Parameters:
//    Data1 - XDTODataObject - object with contact information.
//            - String     - contact information in XML format.
//            - Structure  - contact information details. The expected fields are:
//                 * FieldValues - String
//                                 - Structure
//                                 - ValueList
//                                 - Map - contact information fields.
//                 * Presentation - String - A presentation.
//                                            Used in cases when the "FieldValues" parameter is missing the "Presentation" field.
//                 * Comment - String - a comment. Used when a comment cannot be extracted
//                                          from FieldValues.
//                 * ContactInformationKind - CatalogRef.ContactInformationKinds
//                                           - EnumRef.ContactInformationTypes
//                                           - Structure -
//                                             Used in cases where the type cannot be identified using "FieldsValues".
//    Data2 - XDTODataObject
//            - String
//            - Structure - — see details of the Data1 parameter.
//    Result - ValueTable:
//      * Path      - String - XPath identifying a different value. The "ContactInformationType" value
//                             means that passed contact information sets have different types.
//      * LongDesc  - String - details of a different attribute in terms of the subject field.
//      * Value1 - String - a value matching the object passed in the Data1 parameter.
//      * Value2 - String - a value matching the object passed in Data2 parameter.
//
//
// Returns:
//     ValueTable: - A table of diff fields with the following columns:
//        * Path      - String - XPath identifying a different value. The "ContactInformationType" value
//                               means that passed contact information sets have different types.
//        * LongDesc  - String - details of a different attribute in terms of the subject field.
//        * Value1 - String - a value matching the object passed in the Data1 parameter.
//        * Value2 - String - a value matching the object passed in Data2 parameter.
//
Procedure OnDetermineContactInformationDifferences(Val Data1, Val Data2, Result) Export
	
	
EndProcedure

// Additionally checks and handles data about a country from the country classifier.
// 
// Parameters:
//  CountryByClassifier - ValueTableRow:
//    * Code                - String - Country data.
//    * Description       - String - Country data.
//    * DescriptionFull - String - Country data.
//    * CodeAlpha2          - String - Country data.
//    * CodeAlpha3          - String - Country data.
//
Procedure OnCheckCountryAfterCountrySearchInClassifier(CountryByClassifier) Export

	
EndProcedure

#EndRegion

#Region Internal

Procedure AdjustContactInformation(Form, CIRow, ConversionResult) Export
	
	
EndProcedure

#EndRegion

