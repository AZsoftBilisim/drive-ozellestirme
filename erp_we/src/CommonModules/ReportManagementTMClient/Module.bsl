
#Region Private

#Region DocumentFulfillmentStatus

Procedure StateOfImplementationOfAct(ReferencesReportOfCompletedWorks, ExecutionParameters) Export
	
	If Not GeneralPurposeTMServerCall.CheckListOfDocuments(ReferencesReportOfCompletedWorks) Then
		ShowMessageBox(,NStr("vi = 'Lệnh không thể được thực thi cho các chứng từ thuộc các loại khác nhau.';
							|ru = 'Команда не может быть выполнена для документов разного вида.';
							|en = 'Command cannot be executed for documents of different kinds.'; fa = 'Command cannot be executed for documents of different kinds.';
							|it = 'Il comando non può essere eseguito per i documenti di tipo diverso.';
							|pl = 'Polecenie nie może być wykonane dla dokumentów różnego rodzaju.';
							|tr = 'Komut farklı belge türleri için yürütülemez.'"));
		Return;
	EndIf;
	
	IncomingDocuments = New ValueList;
	IncomingDocuments.LoadValues(ReferencesReportOfCompletedWorks);
	
	FormParameters = New Structure("IncomingDocuments", IncomingDocuments);
	
	OpenForm("Report.DocumentFulfillmentStatus.Form.ReportForm", FormParameters);
	
EndProcedure

#EndRegion

#Region CompareSchedulesOfPaymentsAndAccrualsOfCreditDepositLoanContracts

// Opens the report Comparationgradingcreditsdeposits to compare the selected loan and Deposit schedules.
// 
// Parameters:
// 	Referencescharts - Array of CatalogRef.OptionsOfLoansAndDepositsSchedules - references of the selected objects to compare.
// 	ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
Procedure ComparisonOfArbitraryGraphs(Referencescharts,ExecutionParameters) Export
	
	ClearMessages();
	
	CommandExecuteParameters = New Structure("Source,Uniqueness,Window,URL");
	FillPropertyValues(CommandExecuteParameters, ExecutionParameters.CommandDetails.AdditionalParameters);
	
	If Referencescharts.Count() = 0 Then
		Return;
	EndIf;
	
	If ExecutionParameters.Property("Form") Then
		CommandExecuteParameters.Source = ExecutionParameters.Form;
	EndIf;
	
	Filter = New Structure("ScheduleOption1, Contract", Referencescharts[0], GeneralPurposeTMServerCall.ScheduleOwner(Referencescharts[0]));
	IsList = StrFind(CommandExecuteParameters.Source.FormName,"ItemForm") = 0;
	If IsList Then
		If Referencescharts.Count() <= 1 Then
			Text = NStr("vi = 'Để so sánh, cần chọn hai lịch biểu!';
						|ru = 'Для сравнения необходимо выбрать два графика!';
						|en = 'To compare, select two schedules.'; fa = 'To compare, select two schedules.';
						|it = 'Per confronto, è necessario selezionare due grafici!';
						|pl = 'Do porównania należy wybrać dwa harmonogramy!';
						|tr = 'Karşılaştırma için iki grafik seçilmesi gerekiyor!'");
			CommonClientServer.MessageToUser(Text);
			Return;
		EndIf;
		Filter.Insert("ScheduleOption2", Referencescharts[1]);
	Else
		Filter.Insert("ScheduleOption2", Undefined);
	EndIf;
	
	FormParameters = New Structure();
	FormParameters.Insert("VariantKey", "ComparisonOfChartOptionsContext");
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("ReportOptionsCommandsVisibility", False);
	
	OpenForm("Report.CompareSchedulesOfPaymentsAndAccrualsOfCreditDepositLoanContracts.Form", FormParameters);
	
EndProcedure

#EndRegion

Procedure ABCXYZAnalysisOfInventory(ReferenceProducts,ExecutionParameters) Export
	
	FormParameters = New Structure("Products", ReferenceProducts);
	
	If ValueIsFilled(ReferenceProducts) Then
		OpenForm("Report.ABCXYZAnalysisOfInventory.Form", New Structure("Filter,GenerateOnOpen", FormParameters, True), 
			ExecutionParameters.Form);
	EndIf;
	
EndProcedure

Function StatementOfProductSeries_(ReferenceProducts,ExecutionParameters) Export
	
	FormParameters = New Structure("Products", ReferenceProducts);
	
	If ValueIsFilled(ReferenceProducts) Then
		
		OpenForm("Report.ItemsBatchList.Form", New Structure("Filter,GenerateOnOpen", FormParameters, True),
			ExecutionParameters.Form);
		
	EndIf;
	
EndFunction

Procedure SubordinationStructure(ObjectReference, ExecutionParameters) Export
	
	If ValueIsFilled(ObjectReference) Then
		OpenForm("CommonForm.RelatedDocuments",New Structure("FilterObject", ObjectReference));
	EndIf;
	
EndProcedure

Procedure InteractionsByContact(ObjectReference, ExecutionParameters) Export
	
	If ValueIsFilled(ObjectReference) Then
	
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("Contact", ObjectReference);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("InteractionType", "Contact");
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", FilterStructure1);
		FormParameters.Insert("AdditionalParameters", AdditionalParameters);
		FormParameters.Insert("GroupByPartner", True);
		
		OpenForm("DocumentJournal.Interactions.Form.ParametricListForm", FormParameters);
		
	EndIf;
	
EndProcedure

Procedure PartnerSegments(ObjectReference, ExecutionParameters) Export
	
	If ValueIsFilled(ObjectReference) Then
		
		FormParameters = New Structure("Partner", ObjectReference);
		OpenForm("InformationRegister.SegmentPartners.Form.PartnerSegmentsParameter", FormParameters);
		
	EndIf;
	
EndProcedure

#EndRegion
