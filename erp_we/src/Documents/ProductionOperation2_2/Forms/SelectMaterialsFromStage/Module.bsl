
#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillPropertyValues(ThisForm, Parameters, "Stage");
	
	FillInTableOfMaterials();
	
	Items.GroupNoBalancesAvailable.Visible = (TableMaterials.Count() = 0);
	
	SelectGoodsClientServer.CreateSelectionFormHeader(Title, Stage);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	SaveAndCloseNotification = New CallbackDescription(
		"BeforeClosingSaveAndClose", ThisObject);
	
	CommonClient.ShowFormClosingConfirmation(
		SaveAndCloseNotification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableMaterials

&AtClient
Procedure TableMaterialsNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.TableMaterials.CurrentData;
	RecalculateNumberOfUnits(CurrentData);
	
EndProcedure

&AtClient
Procedure TableMaterialsPackageOnChange(Item)
	
	CurrentData = Items.TableMaterials.CurrentData;
	RecalculateNumberOfUnits(CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectRows(Command)
	
	SelectAllRowsOnServer(True);
	
EndProcedure

&AtClient
Procedure ClearRows(Command)
	
	SelectAllRowsOnServer(False);
	
EndProcedure

&AtClient
Procedure MoveToDocument(Command)
	
	If ThereAreSelectedLines() Then
		
		MoveSelectedLinesToDocument();
		
	Else
		
		ClearMessages();
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Bạn phải chọn các dòng để bọc';
				|ru = 'Необходимо выбрать строки для переноса';
				|en = 'Select lines for transfer'; fa = 'Select lines for transfer';
				|it = 'È necessario selezionare le righe da trasferire';
				|pl = 'Należy wybrać wiersze do przeniesienia';
				|tr = 'Aktarılacak satırları seçmeniz gerekmektedir'"));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "TableMaterialsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "TableMaterials.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
EndProcedure

&AtServer
Procedure FillInTableOfMaterials()
	
	TableMaterials.Load(
		Documents.ProductionStage2_2.ResiduesOfProvidedMaterials(Stage, "Characteristic, Series"));
	
EndProcedure

&AtClient
Procedure RecalculateNumberOfUnits(LineOfATabularSection)

	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	BatchProcessingOfTablePartClient.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure SelectAllRowsOnServer(SelectionValue = True)
	
	FoundRows = TableMaterials.FindRows(New Structure("RowIsSelected", Not SelectionValue));
	
	For Each TableRow In FoundRows Do
		
		TableRow.RowIsSelected = SelectionValue;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure MoveSelectedLinesToDocument()
	
	Result = PlaceSelectedRowsInStorage();
	
	Modified = False;
	Close();
	
	NotifyChoice(Result);
	
EndProcedure

&AtServer
Function PlaceSelectedRowsInStorage()
	
	TableOfSelectedRows = TableMaterials.Unload(New Structure("RowIsSelected", True));
	
	Return PutToTempStorage(TableOfSelectedRows);
	
EndFunction

&AtClient
Procedure BeforeClosingSaveAndClose(QuestionResult, AdditionalParameters) Export
	
	MoveSelectedLinesToDocument();
	
EndProcedure

&AtServer
Function ThereAreSelectedLines()
	
	RowsSelected = TableMaterials.FindRows(New Structure("RowIsSelected", True));
	
	Return Not(RowsSelected.Count() = 0);
	
EndFunction

#EndRegion
