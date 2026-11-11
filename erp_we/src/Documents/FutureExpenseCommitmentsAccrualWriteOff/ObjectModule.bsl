#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	FutureExpenseCommitmentsAccrualWriteOffLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	// If the document does not change the amount of reserves, then we will create tasks for calculating the cost.
	If Reserves.Total("NewAmountLocal") = 0
	 And Reserves.Total("NewAmountMan") = 0
	 And Reserves.Total("NewAmountTA") = 0 Then
		InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(Date, Ref, Organization);
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	FutureExpenseCommitmentsAccrualWriteOffLocalization.UndoPosting(ThisObject, Cancel);
	
	// If the document does not change the amount of reserves, then we will create tasks for calculating the cost.
	If Reserves.Total("NewAmountLocal") = 0
	 And Reserves.Total("NewAmountMan") = 0
	 And Reserves.Total("NewAmountTA") = 0 Then
		InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(Date, Ref, Organization);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	DiscountingOfEstimatedObligation = False;
	If ValueIsFilled(ReserveKind) Then
		DiscountingOfEstimatedObligation = Common.ObjectAttributeValue(
			ReserveKind, "ProvisionDiscounting");
	EndIf;
	
	If ValueIsFilled(Organization) And ValueIsFilled(Date) 
		And DiscountingOfEstimatedObligation Then
		
		If Not FutureExpenseCommitments.AccountingForDiscountingReservesIsUsed(EndOfMonth(Date), Organization) Then
			DiscountingOfEstimatedObligation = False;
		EndIf;
	Else
		DiscountingOfEstimatedObligation = False;		
	EndIf;
	
	If Not DiscountingOfEstimatedObligation Then
		NotCheckedAttributeArray.Add("DiscountRate");
	EndIf;
	
	If DiscountingOfEstimatedObligation Then
		MessageTemplate = NStr("vi = 'Chưa điền cột ""Ngày thực hiện mới"" trong dòng %1';
								|ru = 'Не заполнена колонка ""Новая дата исполнения"" в строке %1';
								|en = 'The ""New execution date"" column is not filled in line %1'; fa = 'The ""New execution date"" column is not filled in line %1';
								|it = 'Не заполнена колонка ""Новая дата исполнения"" в строке %1';
								|pl = 'The ""New execution date"" column is not filled in line %1';
								|tr = '%1satırındaki ""Yeni yürütme tarihi"" sütunu doldurulmadı'");
		For Each String In Reserves Do
			If String.SetNewExecutionDate And Not ValueIsFilled(String.NewExecutionDate) Then
				MessageText = StrTemplate(MessageTemplate, String.LineNumber);
				Common.MessageToUser(MessageText, ThisObject, "NewExecutionDate", "", Cancel);
			EndIf;
		EndDo;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	FutureExpenseCommitmentsAccrualWriteOffLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	ItemsAndDimensionsSelectionParameters = Documents.FutureExpenseCommitmentsAccrualWriteOff.ItemsAndDimensionsSelectionParameters(Enums.BusinessTransactions.EmptyRef());
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Date = EndOfMonth(Date);

	// Let's check that there are no more similar documents this month:
	If WriteMode = DocumentWriteMode.Posting Then
		Query = New Query;
		Query.Text = "SELECT
		               |	FutureExpenseCommitmentsAccrualWriteOff.Ref AS Ref
		               |FROM
		               |	Document.FutureExpenseCommitmentsAccrualWriteOff AS FutureExpenseCommitmentsAccrualWriteOff
		               |WHERE
		               |	FutureExpenseCommitmentsAccrualWriteOff.Ref <> &Ref
		               |	AND BEGINOFPERIOD(FutureExpenseCommitmentsAccrualWriteOff.Date, MONTH) = BEGINOFPERIOD(&Date, MONTH)
		               |	AND FutureExpenseCommitmentsAccrualWriteOff.Organization = &Organization
		               |	AND FutureExpenseCommitmentsAccrualWriteOff.ReserveKind = &ReserveKind
		               |	AND FutureExpenseCommitmentsAccrualWriteOff.Posted";
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("Date", Date);
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("ReserveKind", ReserveKind);
		Result = Query.Execute();
		Selection = Result.Select();
		If Selection.Next() Then
			MessageText = NStr("vi = 'Theo doanh nghiệp ""%1"" có dạng dự phòng ""%2"" trong ""%3"" tháng đã tạo chứng từ ""%4"".';
								|ru = 'По организации ""%1"" с видом резервов ""%2"" за ""%3"" месяц уже оформлен документ ""%4"".';
								|en = 'The %4 document is already registered for the %1 company with the %2 reserve kind for %3 month.'; fa = 'The %4 document is already registered for the %1 company with the %2 reserve kind for %3 month.';
								|it = 'Per l''azienda ""%1"" con il tipo di riserve ""%2"" per ""%3"" mese è stato già creato il documento ""%4"".';
								|pl = 'Dla firmy ""%1"" z rodzajem rezerw ""%2"" za miesiąc ""%3"" jest już sporządzony dokument ""%4"".';
								|tr = '""%3"" ayı için ""%2"" rezerv türüne sahip ""%1"" iş yeri için ""%4"" belgesi artık düzenlendi.'");
			MessageText = StrTemplate(MessageText, Organization, ReserveKind, Format(Date, NStr("vi = 'ДФ=''ММММ''';
																								|ru = 'ДФ=''ММММ''';
																								|en = 'DF=''MMMM'''; fa = 'DF=''MMMM''';
																								|it = 'FD=''MMMM''';
																								|pl = 'DF=''MMMM''';
																								|tr = 'DF=''MMMM'''")), Selection.Ref);
			CommonClientServer.MessageToUser(MessageText, Ref, , , Cancel);
			Return;
		EndIf;
	EndIf;
	
	If ValueIsFilled(ReserveKind) Then
		ReserveType = Common.ObjectAttributeValue(ReserveKind, "ReserveType");
		TheseAreReservesOfLiquidationObligations = ReserveType
			= PredefinedValue("Enum.TypesOfProvisionsAndContingentLiabilities.ResidualLiabilities");
		
		If TheseAreReservesOfLiquidationObligations Then
			For Each ReserveLine In Reserves Do
				If ValueIsFilled(ReserveLine.CurrentTAAmount) Then
					ReserveLine.CurrentTAAmount = 0;
				EndIf;
				If ValueIsFilled(ReserveLine.NewAmountTA) Then
					ReserveLine.NewAmountTA = 0;
				EndIf;
				If ReserveLine.SetNewTAAmount Then
					ReserveLine.SetNewTAAmount = False;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Reserves");
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	FutureExpenseCommitmentsAccrualWriteOffLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	ItemsAndDimensionsSelectionParameters = Documents.FutureExpenseCommitmentsAccrualWriteOff.ItemsAndDimensionsSelectionParameters(Enums.BusinessTransactions.EmptyRef());
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FutureExpenseCommitmentsAccrualWriteOffLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	If TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("Date") Then
			ThisObject.Date = FillingData.Date;
		EndIf;
		CheckStructure = New Structure("Organization, ReserveKind");
		FillPropertyValues(CheckStructure, FillingData);
		If ValueIsFilled(CheckStructure.Organization) And ValueIsFilled(CheckStructure.ReserveKind) Then
			Reserves.Load(Documents.FutureExpenseCommitmentsAccrualWriteOff.DataForFillingReserves(ThisObject).Unload());
		EndIf;
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.FutureExpenseCommitmentsAccrualWriteOff.ItemsAndDimensionsSelectionParameters(Enums.BusinessTransactions.EmptyRef());
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Reserves");
	
EndProcedure

#EndRegion

#EndIf
