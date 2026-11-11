#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	Tasks.BudgetTask.CheckAvailabilityOfBudgetTaskForDocument(ThisObject, Cancel);
	If Not Cancel Then
		CheckDocumentSComplianceWithBudgetTask(Cancel);
	EndIf;
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If ValueIsFilled(BudgetBalanceItem) Then
		IndicatorParameters = Common.ObjectAttributesValues(BudgetBalanceItem,
		"RecordByQuantity, RecordByCurrency");
		If Not IndicatorParameters.RecordByQuantity Then
			NotCheckedAttributeArray.Add("BalanceOfEstimate.Count");
		EndIf;
		If Not IndicatorParameters.RecordByCurrency Then
			NotCheckedAttributeArray.Add("BalanceOfEstimate.Currency");
			NotCheckedAttributeArray.Add("BalanceOfEstimate.AmountInCurrency");
		EndIf;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckDocumentSComplianceWithBudgetTask(Cancel)
	
	If AdditionalProperties.Property("BudgetTask")
		And ValueIsFilled(AdditionalProperties.BudgetTask) Then
		Return;
	EndIf;
	
	UseBudgetProcess = GetFunctionalOption("UseBudgetProcess");
	
	If UseBudgetProcess And Not Users.RolesAvailable("EditingBudgetingDataOutsideProcesses")
		And Not Users.IsFullUser(, , True) Then
		
		PopulationSettings = Documents.SettingOfEstimatesOpeningBalance.SettingsForFillingOutDocumentForBudgetIssue(
			Ref, BudgetBalanceItem);
		If PopulationSettings = Undefined Then
			Return;
		EndIf;
		
		SettingsLines = PopulationSettings.Setting.Copy(New Structure("Scenario", Scenario));
		If SettingsLines.Count() = 0 Then
			If ValueIsFilled(Scenario) Then
				ErrorText = NStr("vi = 'Trong nhiệm vụ ngân sách đang hoạt động theo chứng từ không có tùy chỉnh điền theo tất cả kịch bản.';
								|ru = 'В активной бюджетной задаче по документу нет настроек заполнения по всем сценариям.';
								|en = 'There are no population settings by all scenarios in the active budget task for the document.'; fa = 'There are no population settings by all scenarios in the active budget task for the document.';
								|it = 'There are no population settings by all scenarios in the active budget task for the document.';
								|pl = 'There are no population settings by all scenarios in the active budget task for the document.';
								|tr = 'Belgeye ait aktif bütçe görevinde tüm senaryolara göre doldurma ayarı bulunmamaktadır.'");
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
					"vi = 'Trong nhiệm vụ ngân sách đang hoạt động theo chứng từ không có tùy chỉnh điền theo kịch bản %1';
					|ru = 'В активной бюджетной задаче по документу нет настроек заполнения по сценарию %1';
					|en = 'There are no population settings by the %1 scenario in the active budget task for the document'; fa = 'There are no population settings by the %1 scenario in the active budget task for the document';
					|it = 'There are no population settings by the %1 scenario in the active budget task for the document';
					|pl = 'There are no population settings by the %1 scenario in the active budget task for the document';
					|tr = 'Belgeye ait aktif bütçe görevinde %1 senaryosuna göre doldurma ayarı bulunmamaktadır'"), Scenario);
			EndIf;
			Common.MessageToUser(ErrorText, PopulationSettings.BudgetTask, , , Cancel);
			Return;
		EndIf;
		
		BalanceAnalysts = TMCommonUse.CollapsedCopyOfTable(BalanceOfEstimate, "Organization, Department");
		TheStructureOfTheSearch = New Structure("Organization, Department");
		For Each DimensionLeftovers In BalanceAnalysts Do
			FillPropertyValues(TheStructureOfTheSearch, DimensionLeftovers);
			SettingString = SettingsLines.FindRows(TheStructureOfTheSearch);
			If SettingString.Count() = 0 Then
				If ValueIsFilled(DimensionLeftovers.Organization) And ValueIsFilled(DimensionLeftovers.Department) Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
						"vi = 'Trong nhiệm vụ ngân sách đang hoạt động theo chứng từ không có tùy chỉnh điền theo doanh nghiệp %1 và bộ phận %2.';
						|ru = 'В активной бюджетной задаче по документу нет настройки заполнения по организации %1 и подразделению %2.';
						|en = 'There is no population setting by the %1 company and the %2 business unit in the active budget task for the document.'; fa = 'There is no population setting by the %1 company and the %2 business unit in the active budget task for the document.';
						|it = 'There is no population setting by the %1 company and the %2 business unit in the active budget task for the document.';
						|pl = 'There is no population setting by the %1 company and the %2 business unit in the active budget task for the document.';
						|tr = 'Belgeye ait aktif bütçe görevinde %1 iş yeri ve %2 departmanı için doldurma ayarı bulunmamaktadır.'"),
						DimensionLeftovers.Organization, DimensionLeftovers.Department);
				ElsIf ValueIsFilled(DimensionLeftovers.Organization) Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
						"vi = 'Trong nhiệm vụ ngân sách đang hoạt động theo chứng từ không có tùy chỉnh điền theo doanh nghiệp %1 và tất cả bộ phận.';
						|ru = 'В активной бюджетной задаче по документу нет настройки заполнения по организации %1 и всем подразделениям.';
						|en = 'There is no population setting by the %1 company and all business units in the active budget task for the document.'; fa = 'There is no population setting by the %1 company and all business units in the active budget task for the document.';
						|it = 'There is no population setting by the %1 company and all business units in the active budget task for the document.';
						|pl = 'There is no population setting by the %1 company and all business units in the active budget task for the document.';
						|tr = 'Belgeye ait aktif bütçe görevinde %1 iş yeri ve tüm departmanlar için doldurma ayarı bulunmamaktadır.'"),
						DimensionLeftovers.Organization);
				ElsIf ValueIsFilled(DimensionLeftovers.Department) Then
					ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
						"vi = 'Trong nhiệm vụ ngân sách đang hoạt động theo chứng từ không có tùy chỉnh điền theo bộ phận %1 và tất cả doanh nghiệp.';
						|ru = 'В активной бюджетной задаче по документу нет настройки заполнения по подразделению %1 и всем организациям.';
						|en = 'There is no population setting by all companies and the %1 business unit in the active budget task for the document.'; fa = 'There is no population setting by all companies and the %1 business unit in the active budget task for the document.';
						|it = 'There is no population setting by all companies and the %1 business unit in the active budget task for the document.';
						|pl = 'There is no population setting by all companies and the %1 business unit in the active budget task for the document.';
						|tr = 'Belgeye ait aktif bütçe görevinde %1 departmanı ve tüm iş yerleri için doldurma ayarı bulunmamaktadır.'"),
						DimensionLeftovers.Department);
				Else
					ErrorText = NStr(
						"vi = 'Trong nhiệm vụ ngân sách đang hoạt động theo chứng từ không có tùy chỉnh điền theo tất cả doanh nghiệp và bộ phận.';
						|ru = 'В активной бюджетной задаче по документу нет настройки заполнения по всем организациям и подразделениям.';
						|en = 'There is no population setting by all companies and business units in the active budget task for the document.'; fa = 'There is no population setting by all companies and business units in the active budget task for the document.';
						|it = 'There is no population setting by all companies and business units in the active budget task for the document.';
						|pl = 'There is no population setting by all companies and business units in the active budget task for the document.';
						|tr = 'Belgeye ait aktif bütçe görevinde tüm iş yerleri ve departmanlar için doldurma ayarı bulunmamaktadır.'");
				EndIf;
				Common.MessageToUser(ErrorText, PopulationSettings.BudgetTask, , , Cancel);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf