
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ProcessFormParameters();
	SetDynamicListProperties();
	SetFilters(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	SetFilters(ThisObject);
	SetListParameters(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	SetFilters(ThisObject);
	SetListParameters(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterIndividualOnChange(Item)
	
	SetFilters(ThisObject);
	SetListParameters(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SetListParameters(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CompleteSelection();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	CompleteSelection();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ConfigureDependentFormElementsOnServer()

	If Not GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
		Items.ListLineOfBusiness.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseItemVariants") Then
		Items.ListCharacteristic.Visible = False;
	EndIf;
	
	If SelectionBasedOnLineData Then
		Items.FilterIndividual.InputHint = NStr("vi = 'Không sử dụng';
												|ru = 'Не используется';
												|en = 'Not applicable'; fa = 'Not applicable';
												|it = 'Non viene utilizzato';
												|pl = 'Nie używane';
												|tr = 'Kullanılmıyor'");
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessFormParameters()
	
	Parameters.Property("Date", FilterDate);
	Parameters.Property("Organization", FilterOrganization);
	Parameters.Property("Department", FilterDepartment);
	Parameters.Property("Products", FilterProducts);
	Parameters.Property("Characteristic", FilterCharacteristic);
	Parameters.Property("Individual", FilterIndividual);

	SelectionBasedOnLineData = 
		Parameters.Property("Products")
		Or Parameters.Property("Characteristic");
		
EndProcedure

&AtServer
Procedure SetDynamicListProperties()
	
	QueryDetails = InventoryInOperationClientServer.DescriptionOfRequestToSelectBatchOfGoodsAndMaterials_UT(PickingParameters(ThisObject));
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryDetails.QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	SetListParameters(ThisObject);

EndProcedure

&AtClientAtServerNoContext
Procedure SetListParameters(Form, QueryDetails = Undefined)
	
	List = Form.List; // DynamicList
	
	If QueryDetails = Undefined Then
		QueryDetails = InventoryInOperationClientServer.DescriptionOfRequestToSelectBatchOfGoodsAndMaterials_UT(PickingParameters(Form));
	EndIf;

	For Each ParameterDetails In QueryDetails.QueryOptions Do
		List.Parameters.SetParameterValue(ParameterDetails.Key, ParameterDetails.Value);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function PickingParameters(Form)
	
	PickingParameters = InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation();
	PickingParameters.Date = Form.FilterDate;
	PickingParameters.Organization = Form.FilterOrganization;
	PickingParameters.Department = Form.FilterDepartment;
	PickingParameters.ForDynamicList = True;
	
	If Form.SelectionBasedOnLineData Then
		PickingParameters.Products = Form.FilterProducts;
		PickingParameters.Characteristic = Form.FilterCharacteristic;
		PickingParameters.Individual = Form.FilterIndividual;
	EndIf;
	
	Return PickingParameters;
		
EndFunction

&AtClient
Procedure CompleteSelection()
	
	If CloseOnChoice Then
		
		RowsCollection = New Array;
		
		CurrentRow = Items.List.CurrentRow;
		
		If CurrentRow <> Undefined Then
			RowsCollection.Add(CurrentRow);
		EndIf;
		
	Else
		RowsCollection = Items.List.SelectedRows;
	EndIf;
	
	ResultingArray = New Array;
	For Each RowID In RowsCollection Do
		
		RowData = Items.List.RowData(RowID);
		
		ValueSelected = InventoryInOperationClientServer.NewSelectionValue();
		
		FillPropertyValues(ValueSelected, RowData);
		ValueSelected.NumberOfPackages = RowData.Count;
		
		ResultingArray.Add(ValueSelected);
	
	EndDo;
	
	If ResultingArray.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn vật tư vào sử dụng';
							|ru = 'Необходимо выбрать ТМЦ в эксплуатации';
							|en = 'Select inventory in operation'; fa = 'انتخاب موجودی در حال بهره‌برداری';
							|it = 'È necessario selezionare il bene materiale in lavorazione';
							|pl = 'Należy wybrać zapasy w eksploatacji';
							|tr = 'Kullanımdaki stokun seçilmesi gereklidir'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	If CloseOnChoice Then
		NotifyChoice(ResultingArray[0]);
	Else
		NotifyChoice(ResultingArray);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFilters(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List, "Organization", Form.FilterOrganization,,, ValueIsFilled(Form.FilterOrganization));
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List, "Department", Form.FilterDepartment,,, ValueIsFilled(Form.FilterDepartment));
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List, "Individual", Form.FilterIndividual,,, ValueIsFilled(Form.FilterIndividual));
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_FilterDate" Then
		FilterDateOnChange(Items.FilterDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
