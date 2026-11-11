
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	DescriptionOfMarketingEventTypes = New TypeDescription("CatalogRef.MarketingActivities");
	UseMarketingActivities = GetFunctionalOption("UseMarketingActivities");
	TypeMarketingEvent = Type("CatalogRef.MarketingActivities");
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	For Each AvailableType In Metadata.ChartsOfCharacteristicTypes.ChannelsOfAdvertisingImpacts.Type.Types() Do
		
		If (Not (AvailableType = TypeMarketingEvent
			And Not UseMarketingActivities))
			Or (Object.ValueType = DescriptionOfMarketingEventTypes
			And AvailableType = TypeMarketingEvent) Then
			
			TypesArray = New Array;
			TypesArray.Add(AvailableType);
			If AvailableType = Type("CatalogRef.Partners") And UsePartnersAsCounterparties Then
				Items.ValueType.ChoiceList.Add(New TypeDescription(TypesArray), NStr("vi = 'Đối tác';
																					|ru = 'Контрагент';
																					|en = 'Counterparty'; fa = 'طرف حساب';
																					|it = 'Controparte';
																					|pl = 'Counterparty';
																					|tr = 'Cari hesap'"));
			Else
				Items.ValueType.ChoiceList.Add(New TypeDescription(TypesArray));
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Object.Ref.IsEmpty()
		And Not Object.ValueType.Types().Count() = 1 Then
		Object.ValueType = Items.ValueType.ChoiceList[0].Value;
	EndIf;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not ValueIsFilled(Object.ValueType) Then
	
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra kiểu tương tác';
												|ru = 'Не указан тип воздействия.';
												|en = 'Impact type is not specified.'; fa = 'Impact type is not specified.';
												|it = 'Tipo di effetto non indicato.';
												|pl = 'Nie określono typu interakcji.';
												|tr = 'Etkileşim türü belirtilmedi.'"),"ValueType","Object.ValueType");
		Cancel = True;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
