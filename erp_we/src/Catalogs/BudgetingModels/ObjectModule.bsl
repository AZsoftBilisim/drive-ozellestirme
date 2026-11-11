#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	BudgetingServer.CheckInstanceOfRoutineTask(ThisObject, Cancel);
	If Not IsNew()
		And LimitsByBudgetingDataServer.BudgetingModelIsUsedInLimitSettings(Ref) Then
		ComparisonAttributes = "Status,ValidOnDate,ValidToDate,DeletionMark";
		InitialAttributes = Common.ObjectAttributesValues(Ref, ComparisonAttributes);
		CurDetails_ = New Structure(ComparisonAttributes);
		FillPropertyValues(CurDetails_, ThisObject, ComparisonAttributes);
		If Not TMCommonUseClientServer.StructuresAreEqual(InitialAttributes, CurDetails_, ComparisonAttributes) Then
			SetOfCacheSettingsLimits = InformationRegisters.BudgetingLimitSettingsCache.CreateRecordSet();
			SetPrivilegedMode(True);
			SetOfCacheSettingsLimits.Write();
			SetPrivilegedMode(False);
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If Not IsFolder Then
		ScheduledJob = Undefined;
	EndIf;
	
EndProcedure
Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	BudgetingServer.DeleteInstanceOfRoutineTask(ThisObject, Cancel);
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not IsFolder Then
		
		Query = New Query;
		
		Query.Text = 
		"SELECT TOP 1
		|	BudgetingSteps.Ref
		|FROM
		|	Catalog.BudgetingSteps AS BudgetingSteps
		|WHERE
		|	BudgetingSteps.Owner = &Ref";
		
		Query.SetParameter("Ref", Ref);
		
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		
		If Not SelectionDetailRecords.Next() Then
			
			CatalogObject = Catalogs.BudgetingSteps.CreateFolder();
			CatalogObject.Owner = Ref;
			CatalogObject.Periodicity = Periodicity;
			CatalogObject.StageExecutionProcedure = Enums.BudgetingStageExecutionProcedure.Parallel;
			CatalogObject.StartCondition = Enums.TypesOfBudgetingStepStartConditions.BeforePeriodStart;
			CatalogObject.TypePeriod = Enums.TypesOfBudgetingStepDurations.CalendarDays;
			CatalogObject.Write();
			
		EndIf;
	
	EndIf;
	
	BudgetingServer.SetParametersForRoutineTaskInstance(ThisObject, Cancel);
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	Var Errors;
	
	If Not IsFolder Then
		If Status = Enums.BudgetingModelStatuses.Closed_ Then
			CheckedAttributes.Add("ValidToDate");
		EndIf;
		If ValueIsFilled(ValidToDate) Then
			If ValidToDate <= ValidOnDate Then
				ErrorText = NStr("vi = 'Ngày kết thúc không thể nhỏ hơn ngày bắt đầu';
								|ru = 'Дата окончания действия модели не может быть меньше даты начала действия';
								|en = 'Model expiration date cannot be less than the model effective date'; fa = 'Model expiration date cannot be less than the model effective date';
								|it = 'La data di scadenza del modello non può essere antecedente alla data d''inizio';
								|pl = 'Data zakończenia okresu obowiązywania modelu nie może być wcześniejsza od daty rozpoczęcia';
								|tr = 'Model eylem sonlanma tarihleri eylem başlangıç tarihinden daha erken olamaz'");
				CommonClientServer.AddUserError(Errors, "ValidToDate", ErrorText, "");
			EndIf;
		EndIf;
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

#EndRegion

#EndIf