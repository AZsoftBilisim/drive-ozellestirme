////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// The form is parameterized:
//     the node of the information base - the Planobmainlink - the exchange node for which the configuration is taking place
//     Selection period - Standard Period - general selection period
//     Selection - Data collection form, Assignment table - description of the selection for editing.
//                                When describing the selection, the columns are used:
//                                    Full Metadata name - String - metadata name, for selection
//                                    Selection - Selection of the selected - description of the selection
//                                    The selection of the period is Boolean                - True if the general selection period is applicable
//                                    Period - Standard Period - the total selection period for the row.
//
// The form should return as a result of the selection a structure with the fields:
//     Selection view - String - text description of the selection
//     Selection period - Standard period - the general selection period, if used
//     Selection - Data FormCollection, assignment tables - completed data
//                           Columns similar to the input parameter are used: 
//                           Full Data name, Selection, Period selection, Period.
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseNode = Parameters.InfobaseNode ;
	FilterPeriod1           = Parameters.FilterPeriod1;
	
	// All possible organizations
	For Each ListItem In AvailableNodeOrganizations(InfobaseNode) Do
		FillPropertyValues(CompaniesList.Add(), ListItem);
	EndDo;
	
	// We arrange the notes according to the incoming parameter
	InstallMarked(Parameters.Filter);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectWithMark(Command)
	NotifyChoice(SelectionResult());
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function AvailableNodeOrganizations(InfobaseNode)
	
	UseFilterByCompanies = Common.ObjectAttributeValue(InfobaseNode, "UseFilterByCompanies");
	
	If UseFilterByCompanies Then
		// Organizations from the tabular part 
		SourceRequest = New Query("SELECT ALLOWED
			|	OrganizingExchangePlan.Organization              AS Organization,
			|	OrganizingExchangePlan.Organization.Description AS Description
			|FROM
			|	ExchangePlan.DataSynchronizationViaUniversalFormat.Companies AS OrganizingExchangePlan
			|WHERE
			|	OrganizingExchangePlan.Ref = &Recipient");
		
		SourceRequest.SetParameter("Recipient", InfobaseNode);
		
	Else
		// All available organizations
		SourceRequest = New Query("SELECT ALLOWED
			|	Companies.Ref       AS Organization,
			|	Companies.Description AS Description
			|FROM
			|	Catalog.Companies AS Companies
			|WHERE
			|	NOT Companies.DeletionMark");
		
	EndIf;
	
	Result = New ValueList;
	
	Selection = SourceRequest.Execute().Select();
	While Selection.Next() Do
		Result.Add(Selection.Organization, Selection.Description);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure InstallMarked(Val FilterTable)
	
	Filter = FilterTable[0].Filter; // DataCompositionFilter
	
	If FilterTable.Count()=0 Or Filter.Items.Count()=0 Then
		// No selection data available
		Return;
	EndIf;
		
	// We know the composition of the selection, since we put it there ourselves - either from the node manager, or as a result 
	// of editing in the same form.
	
	DataString1 = Filter.Items[0];
	Selected_1   = DataString1.RightValue;
	CollectionType = TypeOf(Selected_1);
	
	If CollectionType=Type("ValueList") Then
		For Each Item In Selected_1 Do
			SetArrayOfMarked(Item.Value);
		EndDo;
		
	ElsIf CollectionType=Type("Array") Then
		 SetArrayOfMarked(Selected_1);
		 
	ElsIf CollectionType=Type("CatalogRef.Companies") Then
		ListItem = CompaniesList.FindByValue(Selected_1);
		If ListItem<>Undefined Then
			ListItem.Check = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetArrayOfMarked(Companies)
	For Each Organization In Companies Do
		If TypeOf(Organization)=Type("Array") Then
			SetArrayOfMarked(Organization);
			Continue;
		EndIf;
		ListItem = CompaniesList.FindByValue(Organization);
		If ListItem<>Undefined Then
			ListItem.Check = True;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function SelectionResult()
	
	Result = New Structure;
	Result.Insert("FilterPeriod1", FilterPeriod1);
	
	FilterTable.Clear();
	Result.Insert("Filter", FilterTable);

	ArrayOfSelectedOrganizations = New Array;
	SelectionByOrganizationByLine = "";
	
	For Each ListItem In CompaniesList Do
		If ListItem.Check Then
			ArrayOfSelectedOrganizations.Add(ListItem.Value);
			SelectionByOrganizationByLine = SelectionByOrganizationByLine + ", " + ListItem.Presentation;
		EndIf;
	EndDo;
	
	FIlterRow = Result.Filter.Add();
	FIlterRow.FullMetadataName = "AllDocuments";
	FIlterRow.PeriodSelection = ValueIsFilled(FilterPeriod1);
	FIlterRow.Period       = FilterPeriod1;
	
	FilterComposer = New DataCompositionSettingsComposer;
	FIlterRow.Filter = FilterComposer.Settings.Filter;
	
	If ArrayOfSelectedOrganizations.Count() > 0 Then
		OrganizationFieldName = "Ref.Organization";
		FieldNameType         = "RegistrationObjectType";
		TypeSelectionElement   = Type("DataCompositionFilterItem");
		
		FilterByCompany = FIlterRow.Filter.Items.Add(TypeSelectionElement);
		FilterByCompany.LeftValue  = New DataCompositionField(OrganizationFieldName);
		FilterByCompany.ComparisonType   = DataCompositionComparisonType.InList;
		FilterByCompany.RightValue = ArrayOfSelectedOrganizations;
		FilterByCompany.Use  = True;
		
		SelectionByOrganizationByLine = TrimAll(Mid(SelectionByOrganizationByLine, 2));
		
		Result.Insert( "FilterPresentation", 
		                     StringFunctionsClientServer.SubstituteParametersToString(
			                 NStr("vi = 'Sẽ gửi tất cả chứng từ trong kỳ: %1 
							|và lọc theo doanh nghiệp: %2';
							|ru = 'Будут отправлены все документы за период: %1 
							|с отбором по организациям: %2';
							|en = 'All documents for the period will be sent: %1 
							|with the filter by companies: %2'; fa = 'All documents for the period will be sent: %1 
							|with the filter by companies: %2';
							|it = 'Saranno inviati tutti i documenti per il periodo: %1
							|con filtro per aziende: %2';
							|pl = 'Zostaną wysłane wszystkie dokumenty za okres: %1 
							|z filtrem według firm: %2';
							|tr = 'Dönem için tüm belgeler gönderilecektir: %1 
							| iş yerlerine göre filtre: %2'"),
							Lower(String(FIlterRow.Period.Variant)),
							SelectionByOrganizationByLine
		));
	Else
		Result.Insert( "FilterPresentation", 
		                     StringFunctionsClientServer.SubstituteParametersToString(
			                 NStr("vi = 'Sẽ gửi tất cả chứng từ trong %1';
									|ru = 'Будут отправлены все документы за %1';
									|en = 'All documents for %1 will be sent'; fa = 'All documents for %1 will be sent';
									|it = 'Saranno inviati tutti i documenti per %1';
									|pl = 'Zostaną wysłane wszystkie dokumenty za %1';
									|tr = '%1 için tüm belgeler gönderilecektir'"),
							Lower(String(FIlterRow.Period.Variant))));
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion