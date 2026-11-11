
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Department      = Parameters.Department;
	Description       = Parameters.Description;
	ProductionArea            = Parameters.ProductionArea;
	PlotIsNew         = Parameters.ProductionArea;
	OriginalQuantity = Parameters.Count;
	Count         = Parameters.Count;
	UnitOfMeasure   = Parameters.UnitOfMeasure;
	
	If ValueIsFilled(Parameters.WorkCenter) Then
		If TypeOf(Parameters.WorkCenter) = Type("CatalogRef.WorkCenterTypes") Then
			WorkCenterType    = Parameters.WorkCenter;
			ViewOfTheNewWorkCenter = Parameters.WorkCenter;
		Else
			WorkCenterType    = Common.ObjectAttributeValue(Parameters.WorkCenter, "WorkCenterType");
			ViewOfTheNewWorkCenter = WorkCenterType;
			WorkCenter         = Parameters.WorkCenter;
			WorkCenterNov      = Parameters.WorkCenter;
		EndIf;
	EndIf;
	
	Title = StrTemplate(NStr("vi = 'Chia giao dịch ""%1""';
							|ru = 'Деление операции ""%1""';
							|en = '""%1"" operation division'; fa = '""%1"" operation division';
							|it = '""%1"" operation division';
							|pl = '""%1"" operation division';
							|tr = '""%1"" işleminin bölünmesi'"), Description);
	
	CustomizeFormElements();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NumberOfNewItemsOnChange(Item)
	
	Count = OriginalQuantity - NumberOfNewItems;
	
	FillInUnitPresentation(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Split(Command)
	
	If NumberOfNewItems = 0
			Or Count = OriginalQuantity Then
		
		MessageText = NStr("vi = 'Nhập dữ liệu không chính xác';
							|ru = 'Введены некорректные данные';
							|en = 'Incorrect data entered'; fa = 'Incorrect data entered';
							|it = 'Dati inseriti non sono corretti';
							|pl = 'Zostały wprowadzone nieprawidłowe dane';
							|tr = 'Yanlış veri girildi'");
		CommonClient.MessageToUser(MessageText,,"NumberOfNewItems");
		
		Return;
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("ProductionArea", PlotIsNew);
	Result.Insert("WorkCenter", ?(ValueIsFilled(WorkCenterNov), WorkCenterNov, ViewOfTheNewWorkCenter));
	Result.Insert("Count", NumberOfNewItems);
	
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	Items.NumberOfNewItems.MaxValue = Count;
	
	SelectionOfFunctionalOptions = New Structure("Department", Department);
	SetFormFunctionalOptionParameters(SelectionOfFunctionalOptions);
	Items.DecorationPlot.Visible = GetFunctionalOption("UseProductionSites", SelectionOfFunctionalOptions);
	
	Links = New Array;
	Links.Add(New ChoiceParameterLink("Filter.WorkCenterType", "ViewOfTheNewWorkCenter"));
	If Items.DecorationPlot.Visible Then
		Links.Add(New ChoiceParameterLink("Filter.ProductionArea", "PlotIsNew"));
	EndIf;
	Items.WorkCenterNov.ChoiceParameterLinks = New FixedArray(Links);
	
	FillInUnitPresentation(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInUnitPresentation(Form)

	Form.UnitOfMeasurePresentation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		Form.UnitOfMeasure,
		Form.Count);
		
	Form.UnitOfMeasurementNewRepresentation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		Form.UnitOfMeasure,
		Form.NumberOfNewItems);
	
EndProcedure

#EndRegion