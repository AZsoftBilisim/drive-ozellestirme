
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Period = Common.CommonSettingsStorageLoad("SettingProductPricesDocumentSelectionForm", "DocumentSelectionPeriod");
	
	If Period.EndDate = Date(1, 1, 1) Then
		Period.Variant = StandardPeriodVariant.Month;
	EndIf;
	
	UpdateListOfDocumentsServer();

EndProcedure

&AtServerNoContext
Procedure ShouldSaveSettingsServer(FilterPeriod1)
	
	Common.CommonSettingsStorageSave("SettingProductPricesDocumentSelectionForm", "DocumentSelectionPeriod", FilterPeriod1);

EndProcedure

&AtClient
Procedure PeriodOptionOnChange(Item)
	
	ShouldSaveSettingsServer(Period);
	
EndProcedure

&AtClient
Procedure ExitApp(Command)
	
	DocumentsArray = SelectedDocumentsServer();
	Close(DocumentsArray);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateListOfDocumentsServer();
	
EndProcedure

&AtServer
Procedure UpdateListOfDocumentsServer()
	
	Query = New Query("
	|SELECT ALLOWED
	|	SettingPrices.Ref        AS Ref,
	|	SettingPrices.Number         AS Number,
	|	SettingPrices.Date          AS Date,
	|	SettingPrices.Comment   AS Comment,
	|	SettingPrices.Status        AS Status,
	|	SettingPrices.EmployeeResponsible AS EmployeeResponsible,
	|	SettingPrices.Posted      AS Posted,
	|	SettingPrices.MarketingActivity AS MarketingActivity
	|FROM
	|	Document.PriceSetup AS SettingPrices
	|WHERE
	|	SettingPrices.Date BETWEEN &StartDate AND &EndDate
	|ORDER BY
	|	Date DESC,
	|	Number DESC
	|");
	
	Query.SetParameter("StartDate",    Period.StartDate);
	Query.SetParameter("EndDate", Period.EndDate);
	
	Selection = Query.Execute().Select();
	
	DocumentsTable.Clear();
	
	While Selection.Next() Do
		
		NewRow = DocumentsTable.Add();
		FillPropertyValues(NewRow,Selection);
		
	EndDo;
	
EndProcedure

&AtServer
Function SelectedDocumentsServer()
	
	Filter = New Structure("Selected", True);
	FoundRows = DocumentsTable.FindRows(Filter);
	DocumentsArray = DocumentsTable.Unload(FoundRows, "Ref").UnloadColumn("Ref");
	Return DocumentsArray;
	
EndFunction