
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure // Joining the Server()

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	SetVisibilityOfPremises();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SetVisibilityOfPremises();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure CancelSelectedLines(Command)
	If Object.StorageBins.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa điền bảng ô hàng.';
										|ru = 'Таблица складских ячеек не заполнена.';
										|en = 'Storage bins table is not filled in.'; fa = 'Storage bins table is not filled in.';
										|it = 'La tabella delle celle di deposito non è completa.';
										|pl = 'Tabela komórek magazynowych nie jest wypełniona';
										|tr = 'Ambar hücreleri tablosu doldurulmadı.'"));
		Return;
	ElsIf Items.StorageBins.SelectedRows.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Trong bảng ô hàng không có dòng đã chọn';
										|ru = 'В таблице складских ячеек отсутствуют выделенные строки.';
										|en = 'No rows are selected in the storage bin table.'; fa = 'No rows are selected in the storage bin table.';
										|it = 'Nella tabella delle celle di deposito non vi sono le righe selezionate.';
										|pl = 'W tabeli komórek magazynowych nie ma zaznaczonych wierszy';
										|tr = 'Ambar hücreleri tablosunda seçili satır mevcut değil.'"));
		Return;
	EndIf;
	For Each CurRow In Items.StorageBins.SelectedRows Do
		
		TableRow = Object.StorageBins.FindByID(CurRow);
		
		If TableRow <> Undefined Then
				TableRow.Canceled = True;
		EndIf;
		
	EndDo;
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure CancelAllLines(Command)
	If Object.StorageBins.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa điền bảng ô hàng.';
										|ru = 'Таблица складских ячеек не заполнена.';
										|en = 'Storage bins table is not filled in.'; fa = 'Storage bins table is not filled in.';
										|it = 'La tabella delle celle di deposito non è completa.';
										|pl = 'Tabela komórek magazynowych nie jest wypełniona';
										|tr = 'Ambar hücreleri tablosu doldurulmadı.'"));
		Return;
	EndIf;
	For Each CurRow In Object.StorageBins Do
		
		If CurRow <> Undefined Then
				CurRow.Canceled = True;
		EndIf;
		
	EndDo;
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StorageBins.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.StorageBins.Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, False, True, ));

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	SetVisibilityOfPremises();
EndProcedure

&AtServer
Procedure SetVisibilityOfPremises()
	
	Items.Premise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	
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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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
