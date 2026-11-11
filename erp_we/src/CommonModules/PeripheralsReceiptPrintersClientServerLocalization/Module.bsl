#Region Public


#Region OFDCodes

///////////////////////////////////////////////////////////////////////////////
// Taxation system

// Returns the code of the CCT tax system.
// 
// Parameters:
//  Code - Number
//  KktTaxationSystem - EnumRef.CRETaxationSystemTypes - The KKT taxation system.
// 
Procedure CktTaxSystemCode(Code, KktTaxationSystem) Export
	
EndProcedure

// Returns the CCT tax system by code
// 
// Parameters:
//  Value - EnumRef.CRETaxationSystemTypes
//  CktTaxSystemCode - Number - The code of the KKT taxation system.
// 
Procedure KktTaxSystemByCode(Value, CktTaxSystemCode) Export
	
EndProcedure

// Returns the name of the tax system by code.
// 
// Parameters:
//  Value - String
//  TaxationSystem - Number, Arbitrary - Taxation system
//  Brief1 - Boolean - Brief1
// 
Procedure NameOfTaxSystem(Value, TaxationSystem, Brief1 = False) Export;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Codes of types of documents

// Returns the code of the type of identity document CCT.
// 
// Parameters:
//  Code - Number
//  TypeOfIdentityDocument - EnumRef - Type of identity document
// 
Procedure CodeTypeOfIdentityDocument(Code, TypeOfIdentityDocument) Export
	
	
EndProcedure

// Returns the type of identity document CCT by code.
// 
// Parameters:
//  Value - EnumRef
//  CodeOfTypeOfIdentityDocument - Number - The code of the type of identity document.
// 
Procedure TypeOfIdentityDocumentByCode(Value, CodeOfTypeOfIdentityDocument) Export
	
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Codes of calculations, signs of calculations and objects of calculations

// Returns a text Presentation of the payment type on the KKT according to the FFD version
// 
// Parameters:
//  Description - String
//  PaymentTypeCCT - EnumRef.CREPaymentTypes
//  FDFVersion - String - "1.0", "1.1", "1.2"
// 
Procedure NameOfPaymentTypeCCT(Description, PaymentTypeCCT, FDFVersion) Export
	
	
EndProcedure

// Returns the code for the calculation method attribute.
// 
// Parameters:
//  Code - Number
//  SettlementSubjectFlag - EnumRef.SettlementSubjectFlags - A sign of the subject of calculation.
// 
Procedure CodeForCalculationItemAttribute(Code, SettlementSubjectFlag) Export
	
EndProcedure

// Returns a flag for the calculation method based on the code.
// 
// Parameters:
//  Value - EnumRef.SettlementSubjectFlags
//  CodeForCalculationItemAttribute - Number - The code of the attribute of the subject of calculation.
// 
Procedure AttributeOfSubjectOfCalculationByCode(Value, CodeForCalculationItemAttribute) Export
	
	
EndProcedure

// Returns the name of the attribute of the subject of calculation by code.
// 
// Parameters:
//  Description - String
//  CodeForCalculationItemAttribute -Number - The code of the attribute of the subject of calculation.
// 
Procedure NameOfAttributeOfSubjectOfCalculation(Description, CodeForCalculationItemAttribute) Export
	
EndProcedure

#EndRegion

#EndRegion