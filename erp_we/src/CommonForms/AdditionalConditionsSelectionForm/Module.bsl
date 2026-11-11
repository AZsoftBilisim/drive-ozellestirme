#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Title = Parameters.SelectionFormHeader;
	StructureOfFilledValues = New Structure("NameOfTableToFillIn, NameOfColumnToFillIn", 
													Parameters.NameOfFormElementToFillIn, 
													Parameters.NameOfFormElementDetailsToFillIn);
	
	If Parameters.Property("ProhibitionOfChangingListValues") Then
		Items.ListOfSelectedValuesPresentation.ReadOnly = Parameters.ProhibitionOfChangingListValues;
	EndIf;
	
	If Parameters.Property("SpecialConditions")
		And Parameters.SpecialConditions.Property("TheseAreCashRegisterCashAccountsForCWP")
		And Parameters.SpecialConditions.TheseAreCashRegisterCashAccountsForCWP = True Then
		
		TheseAreCashRegisterCashAccountsForCWP = True;
		Items.InscriptionAdditionalInformation.Title = 
			NStr("vi = 'Không có nhiều hơn một quỹ tiền mặt cho mỗi doanh nghiệp và tất cả quỹ tiền mặt theo một kho bãi.';
				|ru = 'Не более одной кассы для каждой организации и все кассы по одному складу.';
				|en = 'No more than one cash account for each company, and one warehouse for all cash accounts.'; fa = 'No more than one cash account for each company, and one warehouse for all cash accounts.';
				|it = 'Не более одной кассы для каждой организации и все кассы по одному складу.';
				|pl = 'No more than one cash account for each company, and one warehouse for all cash accounts.';
				|tr = 'Her kuruluş için birden fazla yazar kasa ve depo başına tüm yazar kasalar.'");
		
	EndIf;
	Items.ListOfSelectedValuesMarkAllButton.Visible = Not TheseAreCashRegisterCashAccountsForCWP;
	Items.InscriptionAdditionalInformation.Visible = TheseAreCashRegisterCashAccountsForCWP;
	
	If Parameters.ExternalConnectionParameters = Undefined Then
		
		If ValueIsFilled(Parameters.ArrayOfSelectedValues_) Then
			ArrayOfPassedValues = Parameters.ArrayOfSelectedValues_;
		Else
			ArrayOfPassedValues = New Array();
		EndIf;
		
		FillInListOfAvailableValues( ArrayOfPassedValues, 
										  Parameters.NameOfSelectionTable,
										  Parameters.FilterCollection);
	
	Else
		
		If Parameters.ExternalConnectionParameters.JoinType = "ExternalConnection" Then
			
			ErrorMessageString = "";
			
			Connection = DataExchangeServer.ExternalConnectionToInfobase(Parameters.ExternalConnectionParameters);
			
			ErrorMessageString = Connection.DetailedErrorDetails;
			ExternalConnection       = Connection.Join;
			
			If ExternalConnection = Undefined Then
				CommonClientServer.MessageToUser(ErrorMessageString,,,, Cancel);
				Return;
			EndIf;
			
			MetadataObjectProperties = 
				ExternalConnection.DataExchangeExternalConnection.MetadataObjectProperties(Parameters.NameOfSelectionTable);
			
			If ValueIsFilled(Parameters.ArrayOfSelectedValues_) Then
				ArrayOfPassedValues = Parameters.ArrayOfSelectedValues_;
			Else
				ArrayOfPassedValues = New Array();
			EndIf;
			
			If Parameters.ExternalConnectionParameters.CorrespondentVersion_2_1_1_7
				Or Parameters.ExternalConnectionParameters.CorrespondentVersion_2_0_1_6 Then
				
				ResultingCollectionOfObjects = 
				ExternalConnection.DataExchangeExternalConnection.GetTableObjects_2_0_1_6(Parameters.NameOfSelectionTable);
				
				CorrespondentInfobaseTable = Common.ValueFromXMLString(ResultingCollectionOfObjects);
				
			Else
				
				ResultingCollectionOfObjects = 
				ExternalConnection.DataExchangeExternalConnection.GetTableObjects(Parameters.NameOfSelectionTable);
				
				CorrespondentInfobaseTable = ValueFromStringInternal( ResultingCollectionOfObjects);
				
			EndIf;
			
			FillInListOfAvailableValuesExternalConnection( ListOfSelectedValues, 
			ArrayOfPassedValues, 
			CorrespondentInfobaseTable);
			
			If ValueIsFilled(Parameters.FilterCollection) Then
				
				CheckFilterPassageExternalConnection(Parameters.FilterCollection);
				
			EndIf;
			
		ElsIf Parameters.ExternalConnectionParameters.JoinType = "WebService" Then
			
			ErrorMessageString = "";
			
			If Parameters.ExternalConnectionParameters.CorrespondentVersion_2_1_1_7 Then
				
				WSProxy = DataExchangeServer.GetWSProxy_2_1_1_7(Parameters.ExternalConnectionParameters, ErrorMessageString);
				
			ElsIf Parameters.ExternalConnectionParameters.CorrespondentVersion_2_0_1_6 Then
				
				WSProxy = DataExchangeServer.GetWSProxy_2_0_1_6(Parameters.ExternalConnectionParameters, ErrorMessageString);
				
			Else
				
				WSProxy = DataExchangeServer.GetWSProxy(Parameters.ExternalConnectionParameters, ErrorMessageString);
				
			EndIf;
			
			If WSProxy = Undefined Then
				CommonClientServer.MessageToUser(ErrorMessageString,,,, Cancel);
				Return;
			EndIf;
			
			If Parameters.ExternalConnectionParameters.CorrespondentVersion_2_1_1_7
				Or Parameters.ExternalConnectionParameters.CorrespondentVersion_2_0_1_6 Then
				
				CorrespondentInfobaseData = XDTOSerializer.ReadXDTO(WSProxy.GetIBData(Parameters.NameOfSelectionTable));
				
				MetadataObjectProperties = CorrespondentInfobaseData.MetadataObjectProperties;
				CorrespondentInfobaseTable = Common.ValueFromXMLString(CorrespondentInfobaseData.CorrespondentInfobaseTable);
				
			Else
				
				CorrespondentInfobaseData = ValueFromStringInternal(WSProxy.GetIBData(Parameters.CorrespondentInfobaseTableFullName));
				
				MetadataObjectProperties = ValueFromStringInternal(CorrespondentInfobaseData.MetadataObjectProperties);
				CorrespondentInfobaseTable = ValueFromStringInternal(CorrespondentInfobaseData.CorrespondentInfobaseTable);
				
			EndIf;
			
			If ValueIsFilled(Parameters.ArrayOfSelectedValues_) Then
				ArrayOfPassedValues = Parameters.ArrayOfSelectedValues_;
			Else
				ArrayOfPassedValues = New Array();
			EndIf;
			
			ReinitializeLinkID(CorrespondentInfobaseTable);
			
			FillInListOfAvailableValuesExternalConnection( ListOfSelectedValues, 
			ArrayOfPassedValues, 
			CorrespondentInfobaseTable);
			
			If ValueIsFilled(Parameters.FilterCollection) Then
				
				CheckFilterPassageExternalConnection(Parameters.FilterCollection);
				
			EndIf;
			
			
		EndIf;
	EndIf;
	
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfSelectedValues

&AtClient
Procedure ListOfSelectedValuesCheckOnChange(Item)
	If TheseAreCashRegisterCashAccountsForCWP Then
		RecalculateAvailability(ListOfSelectedValues);
	EndIf;
EndProcedure

#EndRegion
 
#Region FormCommandsEventHandlers

&AtClient
Procedure WriteClose(Command)
	
	FormClosingParameters = New Structure();
	FormClosingParameters.Insert("AddressOfTableInTemporaryStorage", CreateTableOfSelectedValues());
	FormClosingParameters.Insert("NameOfTableToFillIn",          StructureOfFilledValues.NameOfTableToFillIn);
	FormClosingParameters.Insert("NameOfColumnToFillIn",          StructureOfFilledValues.NameOfColumnToFillIn);
	
	NotifyChoice(FormClosingParameters);
	
EndProcedure

&AtClient
Procedure ClearMark1(Command)
	
	FillInMarks(False);
	If TheseAreCashRegisterCashAccountsForCWP Then
		RecalculateAvailability(ListOfSelectedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	FillInMarks(True);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure FillInListOfAvailableValues( ArrayOfPassedValues, 
											CatalogView,
											AdditionalConditions = Undefined)
	
	Query = New Query("SELECT ALLOWED
	                      |	CatalogForSelectingSelections.Ref AS Presentation,
						  |	&Add_Fields,
						  |	CASE
	                      |		WHEN CatalogForSelectingSelections.Ref IN (&ArrayOfPassedValues)
	                      |			THEN TRUE
	                      |		ELSE FALSE
	                      |	END AS Check
	                      |FROM
	                      |	&CatalogView AS CatalogForSelectingSelections
	                      |WHERE
	                      |	CatalogForSelectingSelections.DeletionMark = FALSE
						  | AND &AddtlFilter
						  |AUTOORDER");
	
	AdditionalSelectionText = "";
	If ValueIsFilled(AdditionalConditions) Then
		
		For Each Filter In AdditionalConditions Do
			
			AdditionalSelectionText = AddConditionText(AdditionalSelectionText, " CatalogForSelectingSelections.", "And", Filter);
			Query.SetParameter(Filter.ParameterName, Filter.ParameterValue);
			
		EndDo; 
		
	EndIf;
	
	If TheseAreCashRegisterCashAccountsForCWP And Lower(CatalogView) = Lower("Catalog.CashRegisters") Then
		AdditionalFieldText = "CatalogForSelectingSelections.Owner AS CompanyCashAccountCashRegister, 
			| CatalogForSelectingSelections.Warehouse AS CashRegisterWarehouse";
		AdditionalSelectionText = AdditionalSelectionText + " AND CatalogForSelectingSelections.CashRegisterType = VALUE(Enum.CashRegisterTypes.StandaloneCWP)";
	Else 
		AdditionalFieldText = "TRUE";
	EndIf;
	Query.Text = StrReplace(Query.Text, "AND &AddtlFilter", AdditionalSelectionText);
	Query.Text = StrReplace(Query.Text, "&Add_Fields", AdditionalFieldText);
	
	Query.Text = StrReplace(Query.Text, "&CatalogView", CatalogView);
	Query.SetParameter("ArrayOfPassedValues", ArrayOfPassedValues);
	
	ListOfSelectedValues.Load(Query.Execute().Unload());
	
	For Each ListItem In ListOfSelectedValues Do
		
		If TypeOf(ListItem.Presentation) <> Type("String") Then
			ListItem.Id = String(ListItem.Presentation.UUID());
		EndIf;
		
	EndDo;
	
	If TheseAreCashRegisterCashAccountsForCWP Then
		RecalculateAvailability(ListOfSelectedValues);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInListOfAvailableValuesExternalConnection( TableOfCorrespondentDatabaseValues, 
															 ArrayOfPassedValues, 
															 ValueTree)
	
	For Each String In ValueTree.Rows Do
		
		If String.Rows.Count() > 0 Then
			
			FillInListOfAvailableValuesExternalConnection( TableOfCorrespondentDatabaseValues, 
															   ArrayOfPassedValues, 
															   String);
			
		Else
			
			NewRow = TableOfCorrespondentDatabaseValues.Add();
			FillPropertyValues(NewRow, String);
			
			If ArrayOfPassedValues.Find(NewRow.Id) <> Undefined Then
				NewRow.Check = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function CreateTableOfSelectedValues()
	
	TableOfSelectedValues = 
		ListOfSelectedValues.Unload(New Structure("Check", True), "Presentation, Id");
	
	Return PutToTempStorage( TableOfSelectedValues, UUID);
		
EndFunction

&AtServer
Procedure FillInMarks(MarkValue)
	
	TableOfFillableValues = ListOfSelectedValues.Unload();
	TableOfFillableValues.FillValues(MarkValue, "Check");
	ListOfSelectedValues.Load(TableOfFillableValues);
	
EndProcedure

&AtServer
Procedure CheckFilterPassageExternalConnection(FilterCollection)
	
	Query = New Query("SELECT
		|	ValueTable.Presentation,
		|	ValueTable.Check,
		|	ValueTable.Key,
		|	ValueTable.Id
		|INTO ListOfFilteredItems
		|FROM
		|	&ListOfSelectedValues_ AS ValueTable");
	
	Query.SetParameter("ListOfSelectedValues_", ListOfSelectedValues.Unload());
	FirstCondition = True;
	
	For Each Filter In FilterCollection Do
		
		If FirstCondition Then
			
			ConditionConnector = "WHERE";
			FirstCondition      = False;
			
		Else
			
			ConditionConnector = "And";
			
		EndIf;
		
		Query.Text = AddConditionText(Query.Text, " ValueTable.", ConditionConnector, Filter);
		Query.SetParameter(Filter.ParameterName, Filter.ParameterValue);
		
	EndDo; 
	
	Query.Text = Query.Text + "
	                      |;
	                      |SELECT
	                      |	ListOfFilteredItems.Presentation,
	                      |	ListOfFilteredItems.Check,
	                      |	ListOfFilteredItems.Key,
	                      |	ListOfFilteredItems.Id
	                      |FROM
	                      |	ListOfFilteredItems AS ListOfFilteredItems";
	
	ListOfSelectedValues.Load(Query.Execute().Unload());
	
EndProcedure

// Parameters:
//  Filter - Structure - Where:
//    * AttributeOfFilter - String - 
//    * Condition - String - 
//    * ParameterName - String - 
//
// Returns:
//  String - 
//
&AtServer
Function AddConditionText(QueryText, TableName, ConditionConnector, Filter)
	
	QueryText = QueryText + Chars.LF + " " + ConditionConnector 
		+ TableName
		+ Filter.AttributeOfFilter
		+ " " + Filter.Condition  
		+ ?(Filter.Condition = "In", " (","")
		+ " &"
		+ Filter.ParameterName
		+ ?(Filter.Condition = "In", ") ","");

	Return QueryText;
	
EndFunction


// Performs reinitialization of references in the value tree.
// 
// Parameters:
//  CorrespondentInfobaseTable - ValueTree, ValueTreeRow - The collection from the correspondent's database contains, among other things:
//     * Id - String - internal ID of the object.
//
&AtServer
Procedure ReinitializeLinkID(CorrespondentInfobaseTable)
	
	For Each String In CorrespondentInfobaseTable.Rows Do
		
		If String.Rows.Count() > 0 Then
			
			ReinitializeLinkID(String);
			
		Else
			
			String.Id = LinkID(String.Id);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function LinkID(Val LineEXT)
	
	UIDString = Mid(LineEXT, 1 + StrFind(LineEXT, ":"), 32);
	
	Id =
		Mid(UIDString, 25, 8) 
		+ "-" + Mid(UIDString, 21, 4) 
		+ "-" + Mid(UIDString, 17, 4) 
		+ "-" + Mid(UIDString, 1, 4)
		+ "-" + Mid(UIDString, 5, 12);
	
	Return Id;
	
EndFunction

&AtClientAtServerNoContext
Procedure RecalculateAvailability(ListOfSelectedValues)
	
	CompaniesCashAccounts = New Map;
	CashAccountWarehouse = Undefined;
	PickedRows = ListOfSelectedValues.FindRows(New Structure("Check", True));
	For Each Itm In PickedRows Do
		CompanySCashAccount = CompaniesCashAccounts.Get(Itm.CompanyCashAccountCashRegister);
		If CompanySCashAccount = Undefined Then
			CompaniesCashAccounts.Insert(Itm.CompanyCashAccountCashRegister, Itm.Presentation);
		Else
			If CompanySCashAccount <> Itm.Presentation Then
				Itm.Check = False;
			EndIf;
		EndIf;
		If CashAccountWarehouse = Undefined Then
			CashAccountWarehouse = Itm.CashRegisterWarehouse;
		Else
			If CashAccountWarehouse <> Itm.CashRegisterWarehouse Then
				Itm.Check = False;
			EndIf;
		EndIf;
	EndDo;
	
	For Each Itm In ListOfSelectedValues Do
		Itm.AvailabilityOfChoice = 
			(CompaniesCashAccounts.Get(Itm.CompanyCashAccountCashRegister) = Undefined
				Or CompaniesCashAccounts.Get(Itm.CompanyCashAccountCashRegister) = Itm.Presentation)
			And (CashAccountWarehouse = Undefined
				Or CashAccountWarehouse = Itm.CashRegisterWarehouse);
		If Itm.Check And Not Itm.AvailabilityOfChoice Then
			Itm.Check = False;
			RecalculateAvailability(ListOfSelectedValues);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	If Not TheseAreCashRegisterCashAccountsForCWP Then
		Return;
	EndIf;
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfSelectedValuesCheck.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfSelectedValuesPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfSelectedValues.AvailabilityOfChoice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InactiveLineColor);
	Item.Appearance.SetParameterValue("Enabled", False);

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfSelectedValuesCheck.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfSelectedValuesPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfSelectedValues.AvailabilityOfChoice");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorMainKittingAndDelivery);
	Item.Appearance.SetParameterValue("Enabled", True);

EndProcedure

#EndRegion

#EndRegion
