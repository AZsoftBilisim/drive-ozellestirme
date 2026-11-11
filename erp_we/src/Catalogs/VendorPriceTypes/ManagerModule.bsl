#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the default price type
//
// Parameters:
//  PriceKind - CatalogRef.VendorPriceTypes - Type of price,
//	Filters -  Structure - Selection structure, where the Key is the name of the item and the Value is the value of the item.
//
// Returns:
//	CatalogRef.VendorPriceTypes - the found type of prices.
//
Function DefaultPriceType(Val PriceKind, Filters = Undefined) Export
	
	If ValueIsFilled(PriceKind) Then
		Return PriceKind;
	EndIf;
	
	Query = New Query("
	|SELECT ALLOWED TOP 2
	|	TypesOfPrices.Ref AS PriceKind
	|FROM
	|	Catalog.VendorPriceTypes AS TypesOfPrices
	|WHERE
	|	NOT TypesOfPrices.DeletionMark
	|");
	
	If Filters <> Undefined Then
		For Each Filter In Filters Do
			Query.Text = Query.Text + "
				|	AND TypesOfPrices." + Filter.Key + " = &" + Filter.Key;
			Query.SetParameter(Filter.Key, Filter.Value);
		EndDo;
	EndIf;
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 And Selection.Next() Then
		PriceKind = Selection.PriceKind;
	Else
		PriceKind = Catalogs.VendorPriceTypes.EmptyRef();
	EndIf;
	
	Return PriceKind;

EndFunction

// Returns the owner of the price type.
// 
// Parameters:
//  PriceKind - CatalogRef.VendorPriceTypes
// 
// Returns:
//  CatalogRef.Partners
Function OwnerOfPriceType(PriceKind) Export
	
	ReturnValue = Catalogs.Partners.EmptyRef();
	
	If Not ValueIsFilled(PriceKind) Then
		Return ReturnValue;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED TOP 1
		|	VendorPriceTypes.Owner AS Owner
		|FROM
		|	Catalog.VendorPriceTypes AS VendorPriceTypes
		|WHERE
		|	VendorPriceTypes.Ref = &Ref";
	
	Query.SetParameter("Ref", PriceKind);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		ReturnValue = Selection.Owner;
	EndIf;

	Return ReturnValue;

EndFunction

// Gets the object's details that need to be blocked from being changed
//
// Returns:
//	Array - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("Owner");
	Result.Add("Currency");
	Result.Add("PriceIncludesVAT");
	Result.Add("AvailableForPurchase");
	Result.Add("AvailableForSaleToCustomers");

	Return Result;

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Owner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf