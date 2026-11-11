#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region StandardSubsystems

// Enables / disables the use of directory properties.
//
Procedure SetUseOfProperties() Export
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseLocal.Get();
	
	PropertyManager.SetPropertySetParameters(
		"Catalog_Reserves", SetParameters);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// Fills in the details of the reserve account settings that affect the setting
// 	with the corresponding names of the accounting Analytics details.
//
// Parameters:
// 	MatchingNames - Map - the key is the name of the account that is used in setting up accounting accounts
// 		. the value is the corresponding name of the accounting Analytics account.
// 
Procedure FillInMatchingAccountSettingsDetails(MatchingNames) Export
	
	MatchingNames.ReserveKind = "Ref";
	
EndProcedure

#EndRegion

Function UnusedVacationsAllowance() Export
	
	Reserve = Common.PredefinedItem("Catalog.Reserves.UnusedVacationsAllowance");
	If Reserve = Undefined Then
		SetPrivilegedMode(True);
		CreateElements();
		Reserve = Common.PredefinedItem("Catalog.Reserves.UnusedVacationsAllowance");
	EndIf;
	
	Return Reserve;
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	FutureExpenseCommitments.ReservesProcessingOfReceivingSelectionData(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ChoiceForm" Or FormType = "ListForm" Then
		
		If Not Parameters.Property("Filter") Or TypeOf(Parameters.Filter) <> Type("Structure") Then
			Parameters.Insert("Filter", New Structure);
		EndIf;
		
		PurposeUseKey =
			CommonClientServer.StructureProperty(Parameters, "PurposeUseKey", "FutureExpenseCommitments");
		TypesOfReserves = Enums.TypesOfProvisionsAndContingentLiabilities.TypesOfReservesByPurpose(PurposeUseKey);
		CommonClientServer.SupplementStructure(Parameters.Filter, New Structure("ReserveType", TypesOfReserves), False);
		
		Parameters.Insert("PurposeUseKey", PurposeUseKey);
		
		StandardProcessing = False;
		If FormType = "ChoiceForm" Then
			SelectedForm = "ChoiceForm";
		Else
			SelectedForm = "ListForm";
		EndIf;
		
	ElsIf FormType = "ObjectForm" Then
		
		ObjectReference = CommonClientServer.StructureProperty(Parameters, "Key"); // CatalogRef.Reserves
		ChoiceParameters = CommonClientServer.StructureProperty(Parameters, "ChoiceParameters", New Structure);
		CopyingValue = CommonClientServer.StructureProperty(Parameters, "CopyingValue");
		
		If ValueIsFilled(ObjectReference) Then
			ReserveType = Common.ObjectAttributeValue(ObjectReference, "ReserveType");
		ElsIf ValueIsFilled(CopyingValue) Then
			ReserveType = Common.ObjectAttributeValue(CopyingValue, "ReserveType");
		Else
			ReserveType = CommonClientServer.StructureProperty(
				ChoiceParameters, "ReserveType", Enums.TypesOfProvisionsAndContingentLiabilities.OtherItems);
		EndIf;
		
		PurposeUseKey =
			CommonClientServer.StructureProperty(Parameters, "PurposeUseKey", "FutureExpenseCommitments");
		If ReserveType = Enums.TypesOfProvisionsAndContingentLiabilities.Payroll
			And Common.SubsystemExists("SalaryCadresApplications") Then
			PurposeUseKey = "WageReserves";
		EndIf;
		
		Parameters.Insert("PurposeUseKey", PurposeUseKey);
		
		StandardProcessing = False;
		SelectedForm = "ItemForm";
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure CreateElements() Export
	
	ItemDetails = ItemDetails();
	ItemDetails.PredefinedDataName = "UnusedVacationsAllowance";
	ItemDetails.Description = NStr("vi = 'Dự phòng nghỉ phép hàng năm';
									|ru = 'Резерв ежегодных отпусков';
									|en = 'Annual leave reserve'; fa = 'Annual leave reserve';
									|it = 'Riserva di ferie annuali';
									|pl = 'Rezerwa urlopów corocznych';
									|tr = 'Yıllık izin yedeği'", Common.DefaultLanguageCode());
	ItemDetails.ReserveType = Enums.TypesOfProvisionsAndContingentLiabilities.Payroll;
	CreateItemBasedOnDescription(ItemDetails);
	
	RefreshReusableValues();
	
EndProcedure

Function ItemDetails()
	Return New Structure("PredefinedDataName, ReserveType, Description");
EndFunction

Procedure CreateItemBasedOnDescription(ItemDetails)
	
	If ValueIsFilled(ItemDetails.PredefinedDataName) Then
		
		PredefinedRef1 = Common.PredefinedItem("Catalog.Reserves." + ItemDetails.PredefinedDataName);
		If ValueIsFilled(PredefinedRef1) Then
			Item = PredefinedRef1.GetObject();
		Else
			ObjectReference = FindItemByName(ItemDetails.Description);
			If ValueIsFilled(ObjectReference) Then
				Item = ObjectReference.GetObject();
			Else
				Item = CreateItem();
			EndIf;
			Item.PredefinedDataName = ItemDetails.PredefinedDataName;
		EndIf;
		
	Else
		
		ObjectReference = FindItemByName(ItemDetails.Description);
		If ValueIsFilled(ObjectReference) Then
			Item = ObjectReference.GetObject();
		Else
			Item = CreateItem();
		EndIf;
		
	EndIf;
	
	FillPropertyValues(Item, ItemDetails);
	Item.Write();
	
EndProcedure

Function FindItemByName(ElementDescription)
	
	Query = New Query;
	Query.SetParameter("Description", ElementDescription);
	Query.Text =
	"SELECT
	|	Reserves.Ref AS Ref,
	|	CASE
	|		WHEN Reserves.Description = &Description
	|			THEN 1
	|		WHEN Reserves.Description LIKE &Description
	|			THEN 2
	|		ELSE 0
	|	END AS DegreeOfCoincidence
	|FROM
	|	Catalog.Reserves AS Reserves
	|WHERE
	|	(Reserves.Description = &Description
	|			OR Reserves.Description LIKE &Description)
	|	AND NOT Reserves.DeletionMark
	|	AND NOT Reserves.Predefined
	|	AND Reserves.PredefinedDataName = """"
	|
	|ORDER BY
	|	DegreeOfCoincidence";
	
	Selection = Query.Execute().Select();
	
	ReturnValue = Catalogs.Reserves.EmptyRef();
	If Selection.Next() Then
		If Selection.DegreeOfCoincidence <> 0 Then
			ReturnValue = Selection.Ref;
		EndIf;
	EndIf;
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#EndIf