
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.FilterByStep.IsEmpty() Then
		ConfigureSelectionByStage(Parameters.FilterByStep);
	EndIf;
	
	#Region UniversalMechanisms
	
	ToDoListOverridable.OnCreateAtServer(ThisForm, List);
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisForm);
	// End Peripherals
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
		
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	// End Peripherals
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	// Peripherals
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	// End Peripherals
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InfoMessageURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "DisableStageSelection" Then
		
		StandardProcessing = False;
		
		ConfigureSelectionByStage(Undefined);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	ChangeSelectedAvailable = ProductionServer.CommandChangeSelectedIsAvailable(Metadata.Documents.ShiftTask);
	Items.ListChangeSelectedItems.Visible          = ChangeSelectedAvailable;
	Items.ContextMenuChangeSelected.Visible = ChangeSelectedAvailable;
	
EndProcedure

&AtServer
Procedure ConfigureSelectionByStage(Stage)
	
	If Stage = Undefined Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText = 
			"SELECT
			|	DocumentOverridable.Ref        AS Ref,
			|	DocumentOverridable.Number         AS Number,
			|	DocumentOverridable.Date          AS Date,
			|	DocumentOverridable.Status        AS Status,
			|	DocumentOverridable.Department AS Department,
			|	DocumentOverridable.ProductionArea       AS ProductionArea,
			|	DocumentOverridable.Comment   AS Comment
			|FROM
			|	Document.ShiftTask AS DocumentOverridable";
		Common.SetDynamicListProperties(Items.List, ListProperties);
		
		Items.InfoMessage.Visible = False;
		
	Else
		
		// Configuring the list
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText = 
			"SELECT
			|	DocumentOverridable.Ref        AS Ref,
			|	DocumentOverridable.Number         AS Number,
			|	DocumentOverridable.Date          AS Date,
			|	DocumentOverridable.Status        AS Status,
			|	DocumentOverridable.Department AS Department,
			|	DocumentOverridable.ProductionArea       AS ProductionArea,
			|	DocumentOverridable.Comment   AS Comment
			|FROM
			|	Document.ShiftTask AS DocumentOverridable
			|WHERE
			|	(TRUE IN
			|		(SELECT TOP 1
			|			TRUE
			|		FROM
			|			InformationRegister.OperationsToCreateShiftTasks AS Operations
			|		WHERE
			|			Operations.ShiftTask = DocumentOverridable.Ref
			|			AND Operations.Stage = &Stage)
			|	OR TRUE IN
			|		(SELECT TOP 1
			|			TRUE
			|		FROM
			|			Document.ProductionOperation2_2 AS Operations
			|		WHERE
			|			Operations.ShiftTask = DocumentOverridable.Ref
			|			AND Operations.Stage = &Stage
			|			AND Operations.Posted))";
		Common.SetDynamicListProperties(Items.List, ListProperties);
		List.Parameters.SetParameterValue("Stage", Stage);
		
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
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ShiftTask.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

#EndRegion
