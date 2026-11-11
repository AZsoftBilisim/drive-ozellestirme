
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("FilterTypeDepartment", FilterTypeDepartment);
	Parameters.Property("FilterTypeWorkCenter",  FilterTypeWorkCenter);
	Parameters.Property("Department",          Department);
	Parameters.Property("ProductionArea",                ProductionArea);
	Parameters.Property("WorkCenter",           WorkCenter);
	
	ReadDivisionParameters();
	
	SetTypeOfWorkCenter(ThisObject);
	
	SetSelectionByDivisionSection();
	SetSelectionByWorkCenter(ThisObject);
	
	Stage = Undefined;
	If Parameters.Property("Stage", Stage) Then
		ConfigureSelectionByStage(Stage);
	EndIf;
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ProductionOperation2_2"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Property("Department")
		And Parameter.Department = Department Then
		
		Items.OperationsOnControl.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If ValueIsFilled(Department) Then
		
		// Selections are set via parameters, saved settings are not used
		
		Settings.Delete("Department");
		Settings.Delete("ProductionArea");
		Settings.Delete("WorkCenter");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Settings["Department"] <> Undefined Then
		
		FilterTypeDepartment = ?(Not ProductionArea.IsEmpty() And UseAreas, 1, 0);
		
		If TypeOf(WorkCenter) = Type("CatalogRef.WorkCenterTypes")
				Or Not ValueIsFilled(WorkCenter) Then
			FilterTypeWorkCenter = 0;
		Else
			FilterTypeWorkCenter = 1;
		EndIf;
		
		DivisionWhenChangedOnServer(True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer(False);
	
EndProcedure

&AtClient
Procedure FilterProductionAreaOnChange(Item)
	
	PlotWhenChangedOnServer(False);
	
EndProcedure

&AtClient
Procedure FilterWorkCenterOnChange(Item)
	
	SetSelectionByWorkCenter(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterShiftOnChange(Item)
	
	SetSelectionForShiftTask(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterTypeDepartmentOnChange(Item)
	
	If FilterTypeDepartment = 1 Then
		
		Department = Undefined;
		DivisionWhenChangedOnServer(True);
		
	Else
		
		ProductionArea = Undefined;
		PlotWhenChangedOnServer(True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterTypeWorkCenterOnChange(Item)
	
	If ValueIsFilled(WorkCenter) Then
		SelectionValueBeforeChange = WorkCenter;
	Else
		SelectionValueBeforeChange = Undefined;
	EndIf;
	
	SetTypeOfWorkCenter(ThisObject);
	
	If SelectionValueBeforeChange <> Undefined
		And SelectionValueBeforeChange <> WorkCenter Then
		SetSelectionByWorkCenter(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure InfoMessageURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "DisableStageSelection" Then
		
		StandardProcessing = False;
		
		ConfigureSelectionByStage(Undefined);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperationsOnControl

&AtServerNoContext
Procedure OperationsOnControlOnGetDataAtServer(TagName, Settings, Rows)
	
	ProductionAccounting.SetStatusRegistrationInListOfProductionOperations(Rows);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ControlOfOperationsToControl(Command)
	
	If Not TMCommonUseClient.CheckForSelectedLinesInList(Items.OperationsOnControl) Then
		Return;
	EndIf;
	
	CurrentData = Items.OperationsOnControl.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	
	FormParameters = New Structure;
	FormParameters.Insert("ProductionOperation", CurrentData.Ref);
	
	NotificationParameters = New Structure("ProductionOperation", CurrentData.Ref);
	Notification = New CallbackDescription("To_ControlCompletion", ThisObject, NotificationParameters);
	
	OpenForm("Document.ProductionOperation2_2.Form.OperationControl",
		FormParameters,
		ThisObject,
		UUID,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "OperationsOnControl.Date", Items.OperationsOnControlDate.Name);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	UseAreas = ProductionServer.UseAreasForPostoperativeManagement();
	
	Items.SelectionDivisionTitle.Visible = Not UseAreas;
	Items.FilterTypeDepartment.Visible = UseAreas;
	
	//

	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Department") Or Initialize Then
		
		Items.OperationsOnControlShiftTask.Visible = Form.UseShiftTasks;
		Items.SelectionChangeTheTitle.Visible              = Form.UseShiftTasks;
		Items.FilterShift.Visible                       = Form.UseShiftTasks;
		
	EndIf;
	
	If AttributesStructure1.Property("FilterTypeDepartment") Or Initialize Then
			
		Items.FilterDepartment.Visible = (Form.FilterTypeDepartment = 0);
		Items.FilterProductionArea.Visible       = (Form.FilterTypeDepartment = 1);
		
		Links = New Array;
		Links.Add(New ChoiceParameterLink("Filter.Department", "Department"));
		If Form.FilterTypeDepartment = 1 Then
			Links.Add(New ChoiceParameterLink("Filter.ProductionArea", "ProductionArea"));
		EndIf;
		
		Items.FilterWorkCenter.ChoiceParameterLinks = New FixedArray(Links);
		Items.FilterShift.ChoiceParameterLinks = New FixedArray(Links);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure To_ControlCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	ProductionOperation = AdditionalParameters.ProductionOperation;
	
	ProductionAccountingServerCall.RecordResultOfOFOperationControl(
		Result.ProtocolEntries, Result.RecalculateStandards, ProductionOperation);
	
	NotifyChanged(ProductionOperation);
	
	NotificationParameter1 = New Structure;
	NotificationParameter1.Insert("Department", Department);
	NotificationParameter1.Insert("Ref",        ProductionOperation);
	Notify("Write_ProductionOperation2_2", NotificationParameter1, UUID);
	
EndProcedure

#Region SelectionsAreCommon

&AtServer
Procedure DivisionWhenChangedOnServer(SelectionTypeChanged)
	
	ReadDivisionParameters();
	
	SetTypeOfWorkCenter(ThisObject);
	
	SetSelectionByDivisionSection();
	SetSelectionByWorkCenter(ThisObject);
	SetSelectionForShiftTask(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Department" + ?(SelectionTypeChanged, ",FilterTypeDepartment", ""));
	
EndProcedure

&AtServer
Procedure PlotWhenChangedOnServer(SelectionTypeChanged)
	
	Department = ?(ProductionArea.IsEmpty(),
		Undefined,
		Common.ObjectAttributeValue(ProductionArea, "Owner"));
		
	DivisionWhenChangedOnServer(SelectionTypeChanged);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByWorkCenter(Form)
	
	SelectionSet = ValueIsFilled(Form.WorkCenter);
	
	If Form.FilterTypeWorkCenter = 1 Then
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.OperationsOnControl,
			"WorkCenter",
			Form.WorkCenter, 
			DataCompositionComparisonType.Equal,
			,
			SelectionSet);
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.OperationsOnControl,
			"WorkCenterType",
			,
			,
			,
			False);
		
	Else
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.OperationsOnControl,
			"WorkCenter",
			,
			,
			,
			False);
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.OperationsOnControl,
			"WorkCenterType",
			Form.WorkCenter,
			DataCompositionComparisonType.Equal,
			, 
			SelectionSet);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionByDivisionSection()
	
	Department = Department;
	
	CommonClientServer.SetDynamicListFilterItem(
		OperationsOnControl,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		OperationsOnControl,
		"ProductionArea",
		ProductionArea,
		DataCompositionComparisonType.Equal,,
		FilterTypeDepartment = 1);
		
	FOParameters = New Structure(
		"Department",
		?(ValueIsFilled(Department), Department, Undefined));
	SetFormFunctionalOptionParameters(FOParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionForShiftTask(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.OperationsOnControl,
		"ShiftTask",
		Form.Shift,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Form.Shift));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetTypeOfWorkCenter(Form)
	
	If Form.FilterTypeWorkCenter = 0 Then
		ValidType_ = New TypeDescription("CatalogRef.WorkCenterTypes");
	Else
		ValidType_ = New TypeDescription("CatalogRef.WorkCenters");
	EndIf;
	
	Form.WorkCenter = ValidType_.AdjustValue(Form.WorkCenter);
	
EndProcedure

&AtServer
Procedure ConfigureSelectionByStage(Stage)
	
	If Stage = Undefined Then
		
		Items.InfoMessage.Visible = False;
		
	Else
		
		// Setting up an information message
		RowsArray = New Array;
		
		PresentationStage = Documents.ProductionStage2_2.PresentationStage(
			Common.ObjectAttributesValues(Stage, "Number, StageName"));
				
		RowsArray.Add(NStr("vi = 'Đã thiết lập lọc theo công đoạn';
							|ru = 'Установлен отбор по этапу';
							|en = 'Stage filter is set'; fa = 'Stage filter is set';
							|it = 'Impostata la selezione per fase';
							|pl = 'Ustawiono selekcję wg etapu';
							|tr = 'Aşamaya göre filtre yapılandırıldı'"));
		RowsArray.Add(" ");
				
		RowsArray.Add(New FormattedString(
			PresentationStage,
			,
			,
			,
			GetURL(Stage)));
					
		RowsArray.Add(" (");
				
		RowsArray.Add(New FormattedString(NStr("vi = 'ngắt kết nối';
												|ru = 'отключить';
												|en = 'disable'; fa = 'disable';
												|it = 'disattivare';
												|pl = 'disable';
												|tr = 'devre dışı bırak'"),,,, "DisableStageSelection"));
				
		RowsArray.Add(") ");
				
		InfoMessage = New FormattedString(RowsArray);
			
		Items.InfoMessage.Visible = True;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		OperationsOnControl, "Stage", Stage, DataCompositionComparisonType.Equal,, ValueIsFilled(Stage));

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ReadDivisionParameters()
	
	If Department.IsEmpty() Then
		Return;
	EndIf;
	
	FillPropertyValues(
		ThisObject,
		ProductionServer.ProductionBusinessUnitDescription(Department),
		"UseShiftTasks");
	
EndProcedure

#EndRegion

#EndRegion
