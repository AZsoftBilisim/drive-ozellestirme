
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Object.Ref.IsEmpty() Then
		FillOutFormForItem();
	EndIf;
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	ObjectData = FormAttributeToValue("Object");
	ObjectData.CheckForUniqueness(Cancel);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If ChangeAttributesOfItemTraceability Then
		ChangeAttributesOfItemTraceability();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UnitOfMeasureOnChange(Item)
	
	CheckAttributesOfItemTraceability();
	
EndProcedure

&AtClient
Procedure TracedGoodsOnChange(Item)
	
	CheckAttributesOfItemTraceability();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillOutFormForItem()
	
	FillPropertyValues(Object, Parameters.FillingValues);
	
EndProcedure

&AtClient
Procedure CheckAttributesOfItemTraceability()
	
	If Not ChangeAttributesOfItemTraceability Then
	
		Required2Update = False;
		
		CheckAttributesOfItemTraceabilityServer(Required2Update);
		
		If Required2Update And Not ChangeAttributesOfItemTraceability Then
				
			QueryText = NStr("vi = 'Thay đổi mục tin truy xuất nguồn gốc trong mặt hàng liên quan?';
							|ru = 'Изменить реквизиты прослеживаемости в связанной номенклатуре?';
							|en = 'Do you want to edit traceability attributes in related items?'; fa = 'Do you want to edit traceability attributes in related items?';
							|it = 'Изменить реквизиты прослеживаемости в связанной номенклатуре?';
							|pl = 'Do you want to edit traceability attributes in related items?';
							|tr = 'Bağlantılı isimlendirmelerde izlenebilirlik ayrıntılarını değiştirin?'");
			
			ShowQueryBox(New CallbackDescription("CheckAttributesOfItemTraceabilityCompletion", ThisObject),
				QueryText,
				QuestionDialogMode.YesNo);
				
		EndIf;
			
	EndIf;

EndProcedure

&AtServer
Procedure CheckAttributesOfItemTraceabilityServer(Required2Update)
	
	If Not AccessRight("Read", Metadata.Catalogs.Products)
			Or Not AccessRight("Update", Metadata.Catalogs.Products) Then
		Return;
	EndIf;
	
	Required2Update = Catalogs.FEACN.ItIsRequiredToChangeAttributesOfItemSTraceability(Object);

EndProcedure

&AtClient
Procedure CheckAttributesOfItemTraceabilityCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		ChangeAttributesOfItemTraceability = True;
		
	EndIf;
	
EndProcedure

&AtServer
Function StartChangingItemTraceabilityAttributes()

	ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
	Return TimeConsumingOperations.ExecuteProcedure(ExecutionParameters,
		"Catalogs.FEACN.ChangeAttributesOfItemTraceability",
		Object.Ref);

EndFunction

&AtClient
Procedure AtEndOfChangingAttributesOfItemTraceability(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
 
	If Result.Status = "Completed2" Then
		Return;
	EndIf;

EndProcedure

&AtClient
Procedure ChangeAttributesOfItemTraceability()
	
	TimeConsumingOperation = StartChangingItemTraceabilityAttributes();
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Undefined);
	IdleParameters.MessageText = NStr("vi = 'Thay đổi mục tin truy xuất nguồn gốc của danh mục ""Mặt hàng"".';
										|ru = 'Изменение реквизитов прослеживаемости справочника ""Номенкатура"".';
										|en = 'Edit traceability attributes of the ""Items"" catalog.'; fa = 'Edit traceability attributes of the ""Items"" catalog.';
										|it = 'Изменение реквизитов прослеживаемости справочника ""Номенкатура"".';
										|pl = 'Edit traceability attributes of the ""Items"" catalog.';
										|tr = '“Nomenklatür” dizininin izlenebilirlik detaylarının değiştirilmesi.'");
	
	Notification = New CallbackDescription("AtEndOfChangingAttributesOfItemTraceability", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Notification, IdleParameters);
	
EndProcedure

#EndRegion
