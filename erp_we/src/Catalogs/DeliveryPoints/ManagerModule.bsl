//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The name of the delivery point at the address.
// 
// Parameters:
//  AddressValue - String - JSON Presentation of the address
// 
// Returns:
//  String
//
Function AbbreviatedPresentationOfAddress(AddressValue) Export
	
	ParametersForGettingAddress = New Structure("WithoutRepresentations", True);
	
	AddressStructure1 = ContactsManager.InfoAboutAddress(AddressValue, ParametersForGettingAddress);
	
	ExcludedLevels = ExcludedAddressLevels(AddressStructure1);
	For Each Level In ExcludedLevels Do
		
		ClearAddressFieldsByLevel(AddressStructure1, Level);
		
	EndDo;
	
	JsonPresentation = ContactsManager.ContactInformationInJSON(
		AddressStructure1,
		Enums.ContactInformationTypes.Address);
	
	Result = ContactsManager.ContactInformationPresentation(JsonPresentation);
	
	Return Result;
	
EndFunction

// Returns the names of blocked details for the BSP details blocking mechanism.
// 
// Returns:
//  Array of String
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array; // Array of String
	Result.Add("Owner");
	Result.Add("Address");
	Result.Add("DeliveryZone");
	
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array of String - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array; // Array of String
	
	NotAttributesToEdit.Add("*");
	
	Return NotAttributesToEdit;
	
EndFunction

// Defining access rights
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Owner)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners 
	|	ON ContactPersonsForPartners.Owner = ThisList.Owner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Owner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Filter = Parameters.Filter; // Structure
	If Not Filter.Property("NotUsed") Then
		
		Filter.Insert("NotUsed", False);
		
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ChoiceForm"
	  And Parameters.Property("Filter")
	  And Parameters.Filter.Property("Owner")
	  And ValueIsFilled(Parameters.Filter.Owner) Then
		
		SelectedForm = Metadata.Catalogs.DeliveryPoints.Forms.OwnerDeliveryPoints.FullName();
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Information about the owner's main delivery point
//
// Parameters:
//  Owner - CatalogRef.Partners, CatalogRef.Warehouses - Delivery Point Owner
// 
// Returns:
//  Structure:
// * Owner - CatalogRef.Partners, CatalogRef.Warehouses - Delivery Point Owner
// * DeliveryPoint - CatalogRef.DeliveryPoints -
// * DeliveryZone - CatalogRef.DeliveryZones -
// 
Function DeliveryPointInformationMain(Owner) Export
	
	Result = New Structure;
	Result.Insert("Owner", Owner);
	Result.Insert("DeliveryPoint", Catalogs.DeliveryPoints.EmptyRef());
	Result.Insert("DeliveryZone", Catalogs.DeliveryZones.EmptyRef());
	
	If Owner.IsEmpty() Then
		Return Result;
	EndIf;
	
	Query = New Query;
	QueryText =
	"SELECT
	|	DeliveryPoints.Ref AS DeliveryPoint,
	|	DeliveryPoints.DeliveryZone AS DeliveryZone
	|FROM
	|	Catalog.DeliveryPoints AS DeliveryPoints
	|WHERE
	|	DeliveryPoints.Owner = &Owner
	|	AND DeliveryPoints.MainPoint";
	
	Query.Text = QueryText;
	Query.SetParameter("Owner", Owner);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		FillPropertyValues(Result, Selection);
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function ExcludedAddressLevels(AddressStructure1)
	
	ExcludedLevels = New Array; // Array of String
	ExcludedLevels.Add("IndexOf");
	ExcludedLevels.Add("District");
	ExcludedLevels.Add("MunicipalDistrict");
	
	If AddressStructure1.Property("Locality")
		And ValueIsFilled(AddressStructure1.Locality) Then
		
		ExcludedLevels.Add("Settlement");
		ExcludedLevels.Add("City");
		
	EndIf;
	
	Return ExcludedLevels;
	
EndFunction

Function AddressLevelFields(Level)
	
	FieldsNames = New Array; // Array of String
	FieldsNames.Add(Level);
	
	If StrCompare(Level, "IndexOf") <> 0 Then
		
		Suffixes = New Array; // Array of String
		
		Suffixes.Add("TypeFull");
		Suffixes.Add("TypeShort");
		Suffixes.Add("Abbr");
		
		FieldNamePattern = "%1%2";
		For Each Suffix In Suffixes Do
			
			FieldName = StrTemplate(FieldNamePattern, Level, Suffix);
			FieldsNames.Add(FieldName);
			
		EndDo;
		
	EndIf;
	
	Return FieldsNames;
	
EndFunction

Procedure ClearAddressFieldsByLevel(AddressStructure1, Level)
	
	LevelFields = AddressLevelFields(Level);
	
	For Each Field In LevelFields Do
		
		If AddressStructure1.Property(Field) Then
			
			AddressStructure1[Field] = "";
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
