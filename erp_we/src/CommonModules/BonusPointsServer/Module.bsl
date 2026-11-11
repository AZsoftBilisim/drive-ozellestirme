
#Region Public

// The distribution of urgent bonus points is a routine task.
// 
Procedure DistributionOfUrgentBonusPointsRoutineTask() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.AllocateFixedTermBonusPoints);

	If Not GetFunctionalOption("UseLoyaltyPrograms") Then
		Return
	EndIf;
		
	SetPrivilegedMode(True);
	
	WriteLogEvent(NStr("vi = 'Phân bổ điểm thưởng có kỳ hạn';
						|ru = 'Распределение срочных бонусных баллов';
						|en = 'Allocate fixed-term bonus points'; fa = 'تخصیص امتیازهای پاداش مدت‌دار';
						|it = 'Distribuzione punti bonus urgenti';
						|pl = 'Przydzielenie polnych punktów bonusowych';
						|tr = 'Acil bonus puanların dağıtımı'", Common.DefaultLanguageCode()),
		EventLogLevel.Information, , ,
		NStr("vi = 'Bắt đầu phân bổ định kỳ điểm thưởng có kỳ hạn.';
			|ru = 'Начато регламентное распределение срочных бонусных баллов.';
			|en = 'Scheduled allocation of fixed-term bonus points has started.'; fa = 'Scheduled allocation of fixed-term bonus points has started.';
			|it = 'Avviata distribuzione punti bonus urgenti.';
			|pl = 'Rozpoczęto reglamentowane przydzielenie pilnych punktów bonusowych.';
			|tr = 'Acil bonus puanların düzenli dağıtımı başladı.'"));
	
	StartDateOfBonusPointsMechanism_2_5 = Constants.StartDateOfBonusPointsMechanism_2_5.Get();
	
	DistributionIsSuccessful = ProcessReturnsOfAccrualsOfBonusPoints(StartDateOfBonusPointsMechanism_2_5);
	
	If DistributionIsSuccessful Then
		DistributionIsSuccessful = ProcessBonusPointsPaymentReturns(StartDateOfBonusPointsMechanism_2_5);
	EndIf;
	
	If DistributionIsSuccessful Then
		DistributionIsSuccessful = ProcessPaymentsAndAccrualsOfUrgentBonusPoints(StartDateOfBonusPointsMechanism_2_5);
	EndIf;
	
	If DistributionIsSuccessful Then
		ProcessTerminatedActionsOfAccrualOfUrgentBonusPoints(StartDateOfBonusPointsMechanism_2_5);		
	EndIf;
	
	WriteLogEvent(NStr("vi = 'Phân bổ điểm thưởng có kỳ hạn';
						|ru = 'Распределение срочных бонусных баллов';
						|en = 'Allocate fixed-term bonus points'; fa = 'تخصیص امتیازهای پاداش مدت‌دار';
						|it = 'Distribuzione punti bonus urgenti';
						|pl = 'Przydzielenie polnych punktów bonusowych';
						|tr = 'Acil bonus puanların dağıtımı'", Common.DefaultLanguageCode()),
		EventLogLevel.Information, , ,
		NStr("vi = 'Đã kết thúc phân bổ định kỳ điểm thưởng có kỳ hạn.';
			|ru = 'Закончено регламентное распределение срочных бонусных баллов.';
			|en = 'Scheduled allocation of fixed-term bonus points is completed.'; fa = 'Scheduled allocation of fixed-term bonus points is completed.';
			|it = 'È terminata la distribuzione regolamentata dei punti bonus urgenti.';
			|pl = 'Zakończono reglamentowane przydzielenie pilnych punktów bonusowych.';
			|tr = 'Acil bonus puanların düzenli dağıtımı tamamlandı.'"));
	
EndProcedure

// Generates a list of queue task templates.
//
// Parameters:
//  NamesAndAliasesMap - See JobsQueueOverridable.OnDefineHandlerAliases
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.AllocateFixedTermBonusPoints.MethodName);
	
EndProcedure

// It Is Required To Add Register Registered Records Bonus Points
// Parameters:
//	DocumentRef - DocumentRef - the link whose Attribute values you need to get.
//
// Returns:
// Boolean - the add register RegisteredRecorded Bonus points flag.
//
Function ItIsRequiredToAddRegisterRegisteredRecordsBonusPoints(DocumentRef) Export
	
	StartDateOfBonusPointsMechanism_2_5 = Constants.StartDateOfBonusPointsMechanism_2_5.Get();
	
	DocumentAttributeDate = "Date";
	DocumentDate = Common.ObjectAttributeValue(DocumentRef, DocumentAttributeDate);
	
	ThisIsMechanismOfBonusPoints_2_5 = False;
	If BegOfDay(DocumentDate) >= BegOfDay(StartDateOfBonusPointsMechanism_2_5) Then
		ThisIsMechanismOfBonusPoints_2_5 = True;
	EndIf;
	
	If (TypeOf(DocumentRef) = Type("DocumentRef.ReturnOfGoodsFromCustomer") 
		Or TypeOf(DocumentRef) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"))
			And ThisIsMechanismOfBonusPoints_2_5 Then
		MOUTH = Common.ObjectAttributeValue(DocumentRef, "DocumentSalesOfGoodsAndServices");
		If ValueIsFilled(MOUTH) Then
			DateOfImplementationDocument = Common.ObjectAttributeValue(MOUTH, "Date");
			If BegOfDay(DateOfImplementationDocument)< BegOfDay(StartDateOfBonusPointsMechanism_2_5) Then
				ThisIsMechanismOfBonusPoints_2_5 = False;
			EndIf;
		EndIf;
	ElsIf TypeOf(DocumentRef) = Type("DocumentRef.SaleAdjustment") 
			And ThisIsMechanismOfBonusPoints_2_5 Then
		MOUTH = Common.ObjectAttributeValue(DocumentRef, "DocumentBasis");
		If ValueIsFilled(MOUTH) Then
			DateOfImplementationDocument = Common.ObjectAttributeValue(MOUTH, "Date");
			If BegOfDay(DateOfImplementationDocument)< BegOfDay(StartDateOfBonusPointsMechanism_2_5) Then
				ThisIsMechanismOfBonusPoints_2_5 = False;
			EndIf;
		EndIf;
	EndIf;

	Return ThisIsMechanismOfBonusPoints_2_5;
	
EndFunction

// Starts automatic accrual and deduction of points and monitors the result.
// 
// Parameters:
//  AccrualRule - CatalogRef.CustomerRewardProgramRules - rule for awarding points.
//
Procedure PerformAutomaticAccrualAndWriteOffRoutineTask(AccrualRule) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.AutomaticAccrueAndDeductionOfBonusPoints);
	
	If IsBlankString(UserName()) Then
		SetPrivilegedMode(True);
	EndIf;
	
	If Not GetFunctionalOption("UseLoyaltyPrograms") 
		Or Not ValueIsFilled(AccrualRule) Then
		Return;
	EndIf;
	
	LogParameters = New Structure("EventGroup_, Metadata, Data");
	LogParameters.EventGroup_ = NStr("vi = 'Tự động tính và trừ điểm tích lũy. Khởi động theo lịch biểu';
									|ru = 'Автоматическое начисление и списание бонусных баллов. Запуск по расписанию';
									|en = 'Automatic accrual and write-off of bonus points. Run on schedule'; fa = 'Automatic accrual and write-off of bonus points. Run on schedule';
									|it = 'Aggiunta e detrazione dei punti bonus automatica. Avvio programmato';
									|pl = 'Naliczanie automatyczne i rozchód punktów bonusowych. Uruchomienie według harmonogramu';
									|tr = 'Bonus puanlarının otomatik olarak tahakkuk ettirilmesi ve gider yazılması. Programa göre başlatma'");
	LogParameters.Metadata    = AccrualRule.Metadata();
	LogParameters.Data        = AccrualRule;
	
	SegmentsServer.LogRecord(LogParameters, EventLogLevel.Note, "", NStr("vi = 'Khởi động';
																		|ru = 'Запуск';
																		|en = 'Start'; fa = 'شروع';
																		|it = 'Avvio';
																		|pl = 'Start';
																		|tr = 'Başlangıc'"));
	
	Attributes = Common.ObjectAttributesValues(
		AccrualRule,
		"DeletionMark, Description");
	
	// Checks
	If Attributes.DeletionMark Then
		SegmentsServer.LogRecord(LogParameters, EventLogLevel.Error, "",
			NStr("vi = 'Kết thúc';
				|ru = 'Завершение';
				|en = 'End'; fa = 'پایان';
				|it = 'Completamento';
				|pl = 'End';
				|tr = 'Tamamlama'"), NStr("vi = 'Đã đánh dấu xóa phần tử tự động tính và ghi giảm điểm thưởng';
									|ru = 'Элемент автоматического начисления и списания бонусных баллов помечен на удаление';
									|en = 'Item of auto accrual or write-off of bonus points is marked for deletion'; fa = 'Item of auto accrual or write-off of bonus points is marked for deletion';
									|it = 'L''elemento di aggiunta e detrazione dei punti bonus automatica è contrassegnato per la cancellazione';
									|pl = 'Element automatycznego naliczania i rozchodu punktów bonusowych zaznaczony na usunięcie';
									|tr = 'Bonus puanların otomatik olarak tahakkuk ettirilmesi ve kayıttan düşürülmesi öğesi silinmek üzere işaretlenmiştir'"));
		Return;
	EndIf;
	
	BonusPointsServer.PerformAutomaticAccrualsAndDebits(AccrualRule);
	SegmentsServer.LogRecord(LogParameters, EventLogLevel.Note, "",NStr("vi = 'Kết thúc';
																		|ru = 'Завершение';
																		|en = 'End'; fa = 'پایان';
																		|it = 'Completamento';
																		|pl = 'End';
																		|tr = 'Tamamlama'"));
	
EndProcedure

// Performs automatic accrual and debiting of bonus
// points according to the bonus points accrual rule.
// 
// Parameters:
//  AccrualRule - CatalogRef.CustomerRewardProgramRules - accrual rule.
//
Procedure PerformAutomaticAccrualsAndDebits(AccrualRule) Export
	
	AccrualDate = CurrentSessionDate();
	
	AccrualAndWriteOffTable = AccrualAndWriteOffTable(AccrualRule, AccrualDate);

	If AccrualAndWriteOffTable.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	CustomerRewardProgramRules.ActionPeriod AS ActionPeriod,
	|	CustomerRewardProgramRules.NumberOfValidityPeriods AS NumberOfValidityPeriods,
	|	CustomerRewardProgramRules.NumberOfActionStartDelayPeriods AS NumberOfActionStartDelayPeriods,
	|	CustomerRewardProgramRules.PeriodOfActionStartDelay AS PeriodOfActionStartDelay,
	|	CustomerRewardProgramRules.RuleKind AS RuleKind,
	|	CustomerRewardProgramRules.Owner AS LoyaltyProgram
	|FROM
	|	Catalog.CustomerRewardProgramRules AS CustomerRewardProgramRules
	|WHERE
	|	CustomerRewardProgramRules.Ref = &AccrualRule");
	
	Query.SetParameter("AccrualRule", AccrualRule);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		
		AccrueAndDeductionOfBonusPoints = Documents.AccrueAndDeductionOfBonusPoints.CreateDocument();
		AccrueAndDeductionOfBonusPoints.AccrualRule = AccrualRule;
		AccrueAndDeductionOfBonusPoints.Date              = AccrualDate;
		AccrueAndDeductionOfBonusPoints.LoyaltyProgram              = Selection.LoyaltyProgram;
		AccrueAndDeductionOfBonusPoints.RuleKind                               = Selection.RuleKind;
		AccrueAndDeductionOfBonusPoints.NumberOfValidityPeriods               = Selection.NumberOfValidityPeriods;
		AccrueAndDeductionOfBonusPoints.NumberOfActionStartDelayPeriods = Selection.NumberOfActionStartDelayPeriods;
		AccrueAndDeductionOfBonusPoints.PeriodOfActionStartDelay             = Selection.PeriodOfActionStartDelay;
		AccrueAndDeductionOfBonusPoints.ActionPeriod                           = Selection.ActionPeriod;
		
		For Each TSRow In AccrualAndWriteOffTable Do
		
			If AccrueAndDeductionOfBonusPoints.RuleKind = Enums.KindsOfBonusPointAccrualRules.Accrual Then
				NewRow = AccrueAndDeductionOfBonusPoints.Accrual.Add();
			Else
				NewRow = AccrueAndDeductionOfBonusPoints.WriteOff.Add();
			EndIf;
			
			NewRow.Partner = TSRow.Partner;
			NewRow.Points   = TSRow.AccrualAmount;
			
		EndDo;
		
		AccrueAndDeductionOfBonusPoints.Write(DocumentWriteMode.Posting, DocumentPostingMode.Regular);
		
	EndIf;
	
EndProcedure

// Receives data on the partner's bonus points remaining in the loyalty bonus program.
//
// Parameters:
//  LoyaltyProgram - CatalogRef.LoyaltyPrograms - Bonus loyalty program.
//  Partner - CatalogRef.Partners - Partner.
//
// Returns:
//  ValueTable - with columns:
//   * Period - Date - Period.
//   * Sum - Number - The amount.
//   * Update - Number - Amount of change.
//   * Current_Balance - Number - Current balance.
//
Function BalancesAndRegisteredRecordsOfBonusPoints(LoyaltyProgram, Partner) Export
	
	SetPrivilegedMode(True);
	
	BalanceBonusPoints = New ValueTable;
	BalanceBonusPoints.Columns.Add("Period");
	BalanceBonusPoints.Columns.Add("Sum");
	BalanceBonusPoints.Columns.Add("Update");
	BalanceBonusPoints.Columns.Add("Current_Balance");
	
	Query = New Query("
	|SELECT
	|	&LoyaltyProgram AS LoyaltyProgram,
	|	&Partner AS Partner
	|INTO InitialDataIsPreliminary
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InitialDataIsPreliminary.LoyaltyProgram AS LoyaltyProgram,
	|	InitialDataIsPreliminary.Partner AS Partner,
	|	NOT BonusPointState.DiscountCard IS NULL AS CardIsBlocked
	|INTO BonusPointState
	|FROM
	|	InitialDataIsPreliminary AS InitialDataIsPreliminary
	|	LEFT JOIN InformationRegister.BonusPointState AS BonusPointState
	|		ON BonusPointState.DiscountCard.Partner = InitialDataIsPreliminary.Partner
	|		AND BonusPointState.DiscountCard.Owner.LoyaltyProgram = InitialDataIsPreliminary.LoyaltyProgram
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InitialDataIsPreliminary.LoyaltyProgram AS LoyaltyProgram,
	|	InitialDataIsPreliminary.Partner AS Partner,
	|	SUM(ISNULL(BonusPointsToWriteOff.ToWriteOff, 0)) AS ToWriteOff
	|INTO BonusPointsToBeDebitedLoyaltyServer
	|FROM
	|	InitialDataIsPreliminary AS InitialDataIsPreliminary
	|	LEFT JOIN InformationRegister.BonusPointsToWriteOffAndAccrue AS BonusPointsToWriteOff
	|		ON BonusPointsToWriteOff.DiscountCard.Partner = InitialDataIsPreliminary.Partner
	|		AND BonusPointsToWriteOff.LoyaltyProgram = InitialDataIsPreliminary.LoyaltyProgram
	|GROUP BY
	|	InitialDataIsPreliminary.LoyaltyProgram,
	|	InitialDataIsPreliminary.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	""Now"" AS Period,
	|	CASE
	|		WHEN BonusPointsBalancesAndTurnovers.AccruedBalance - 
	|				CASE WHEN (BonusPointsBalancesAndTurnovers.ToWriteOffBalance + BonusPointsToWriteOff.ToWriteOff) > 0 THEN (BonusPointsBalancesAndTurnovers.ToWriteOffBalance + BonusPointsToWriteOff.ToWriteOff) ELSE 0 END >= 0
	|			THEN BonusPointsBalancesAndTurnovers.AccruedBalance - 
	|					CASE WHEN (BonusPointsBalancesAndTurnovers.ToWriteOffBalance + BonusPointsToWriteOff.ToWriteOff) > 0 THEN (BonusPointsBalancesAndTurnovers.ToWriteOffBalance + BonusPointsToWriteOff.ToWriteOff) ELSE 0 END
	|		ELSE 0
	|	END AS Sum
	|INTO OpeningBalance
	|FROM
	|	AccumulationRegister.BonusPoints.Balance(
	|			&StartDate,
	|			(LoyaltyProgram, Partner) IN
	|				(SELECT
	|					BonusPointState.LoyaltyProgram,
	|					BonusPointState.Partner
	|				FROM
	|					BonusPointState
	|				WHERE NOT BonusPointState.CardIsBlocked)) AS BonusPointsBalancesAndTurnovers
	|	INNER JOIN BonusPointsToBeDebitedLoyaltyServer AS BonusPointsToWriteOff
	|		ON BonusPointsBalancesAndTurnovers.Partner = BonusPointsToWriteOff.Partner
	|		AND BonusPointsBalancesAndTurnovers.LoyaltyProgram = BonusPointsToWriteOff.LoyaltyProgram
	|
	|UNION ALL
	|
	|SELECT
	|	""Now"",
	|	0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OpeningBalance.Period AS Period,
	|	SUM(OpeningBalance.Sum) AS Sum
	|FROM
	|	OpeningBalance AS OpeningBalance
	|
	|GROUP BY
	|	OpeningBalance.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPointsBalancesAndTurnovers.DayPeriod AS Period,
	|	CASE
	|		WHEN BonusPointsBalancesAndTurnovers.AccruedClosingBalance - CASE WHEN BonusPointsBalancesAndTurnovers.ToWriteOffClosingBalance > 0 THEN BonusPointsBalancesAndTurnovers.ToWriteOffClosingBalance ELSE 0 END >= 0
	|			THEN BonusPointsBalancesAndTurnovers.AccruedClosingBalance - CASE WHEN BonusPointsBalancesAndTurnovers.ToWriteOffClosingBalance > 0 THEN BonusPointsBalancesAndTurnovers.ToWriteOffClosingBalance ELSE 0 END
	|		ELSE 0
	|	END AS Sum
	|FROM
	|	AccumulationRegister.BonusPoints.BalanceAndTurnovers(
	|			&StartDate,
	|			,
	|			Auto,
	|			RegisterRecords,
	|			(LoyaltyProgram, Partner) IN
	|				(SELECT
	|					BonusPointState.LoyaltyProgram,
	|					BonusPointState.Partner
	|				FROM
	|					BonusPointState
	|				WHERE NOT BonusPointState.CardIsBlocked)) AS BonusPointsBalancesAndTurnovers
	|
	|ORDER BY
	|	Period");

	Query.SetParameter("StartDate",                  CurrentSessionDate());
	Query.SetParameter("LoyaltyProgram", LoyaltyProgram);
	Query.SetParameter("Partner",                     Partner);

	ResultsArray = Query.ExecuteBatch();
	
	// Current balance
	ResultCurBalance = ResultsArray[4]; // QueryResult
	Selection = ResultCurBalance.Select();
	Current_Balance = 0;
	While Selection.Next() Do
		
		NewRow = BalanceBonusPoints.Add();
		NewRow.Period = Selection.Period;
		NewRow.Sum = Selection.Sum;
		Current_Balance = NewRow.Sum;
		NewRow.Current_Balance = True;
		
	EndDo;
	
	// Deductions of points
	ResultOfDebitingPoints = ResultsArray[5]; // QueryResult
	Selection = ResultOfDebitingPoints.Select();
	While Selection.Next() Do
		
		Update = Selection.Sum - Current_Balance;
		
		If Update = 0 Then
			Continue;
		EndIf;
		
		NewRow = BalanceBonusPoints.Add();
		If Update > 0 Then
			NewRow.Period = NStr("vi = 'Tính thông qua';
								|ru = 'Начисление через';
								|en = 'Accrual in'; fa = 'Accrual in';
								|it = 'Aggiunta tra';
								|pl = 'Naliczanie przez';
								|tr = 'Tahakkuk'")
			                   + " " + StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(Int((Selection.Period - CurrentSessionDate())/(24*60*60)), NStr("vi = 'ngày';
																																											|ru = 'день, дня, дней';
																																											|en = 'day, days, days'; fa = 'day, days, days';
																																											|it = 'giorno, giorno, giorni';
																																											|pl = 'dzień, dni, dni';
																																											|tr = 'gün, gün, günler'"))
			                   + " " + "("+Format(Selection.Period,"DLF=D")+"):"
			                   + " " + StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(Update, NStr("vi = 'điểm, điểm, điểm';
																														|ru = 'балл, балла, баллов';
																														|en = 'point, point, points'; fa = 'point, point, points';
																														|it = 'punti';
																														|pl = 'punkt, punktu, punktów';
																														|tr = 'puan, puan, puan'"))
		Else
			NewRow.Period = NStr("vi = 'Giảm thông qua';
								|ru = 'Списание через';
								|en = 'Write-off in'; fa = 'Write-off in';
								|it = 'Detrazione tra';
								|pl = 'Rozchów przez';
								|tr = 'Gider yazma'")
			                   + " " + StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(Int((Selection.Period - CurrentSessionDate())/(24*60*60)), NStr("vi = 'ngày';
																																											|ru = 'день, дня, дней';
																																											|en = 'day, days, days'; fa = 'day, days, days';
																																											|it = 'giorno, giorno, giorni';
																																											|pl = 'dzień, dni, dni';
																																											|tr = 'gün, gün, günler'"))
			                   + " " + "("+Format(Selection.Period,"DLF=D")+"):"
			                   + " " + StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(-Update, NStr("vi = 'điểm, điểm, điểm';
																														|ru = 'балл, балла, баллов';
																														|en = 'point, point, points'; fa = 'point, point, points';
																														|it = 'punti';
																														|pl = 'punkt, punktu, punktów';
																														|tr = 'puan, puan, puan'"))
		EndIf;
		
		NewRow.Sum = Selection.Sum;
		NewRow.Update = Update;
		Current_Balance = Selection.Sum; 
		
	EndDo;
	
	Return BalanceBonusPoints;
	
EndFunction

// Receives data from the loyalty card bonus program.
//
// Parameters:
//  LoyaltyCard - CatalogRef.LoyaltyCards - Loyalty card.
//
// Returns:
//  CatalogRef.LoyaltyPrograms - Bonus loyalty program.
//
Function LoyaltyCardBonusProgram(LoyaltyCard) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	LoyaltyCards.Owner                                                               AS LoyaltyCardKind,
	|	LoyaltyCards.Owner.LoyaltyProgram                                   AS LoyaltyProgram,
	|	LoyaltyCards.Owner.LoyaltyProgram.BonusConversionCurrency          AS Currency,
	|	LoyaltyCards.Owner.LoyaltyProgram.ConversionRateOfBonusesIntoCurrency     AS ConversionRateOfBonusesIntoCurrency,
	|	LoyaltyCards.Partner                                                                AS Partner,
	|	LoyaltyCards.Owner.LoyaltyProgram.DoNotAccruePointsWhenPayingWithBonuses AS DoNotAccruePointsWhenPayingWithBonuses,
	|	LoyaltyCards.Owner.LoyaltyProgram.MaximumSharePayableByPoints AS MaximumSharePayableByPoints
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|WHERE
	|	LoyaltyCards.Ref = &LoyaltyCard");
	Query.SetParameter("LoyaltyCard", LoyaltyCard);
	
	SampleBonusLoyaltyProgram = Query.Execute().Select();
	SampleBonusLoyaltyProgram.Next();
	
	Return SampleBonusLoyaltyProgram;
	
EndFunction

#EndRegion

#Region Private

#Region ProcessingOfReturnOfAccrualsOfBonusPoints

Function ProcessReturnsOfAccrualsOfBonusPoints(SliceDate)
	
	DistributionIsSuccessful = True;
	NumberOfProcessedData = 0;
	RepeatProcessing = True;
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"ScheduledJob.AllocateFixedTermBonusPoints.ProcessReturnsOfAccrualsOfBonusPoints_x100");
	
	While RepeatProcessing Do
		ErrorText = "";
		
		ProcessedDocumentsCount = WithdrawReturnsOfAccrualsOfBonusPointsForProcessing(SliceDate,,ErrorText);
		RepeatProcessing = Not (ProcessedDocumentsCount = 0);
		
		If ValueIsFilled(ErrorText) Then
			DistributionIsSuccessful = False;
			MessageText = NStr("vi = 'Khi phân bổ các khoản hoàn trả khi ghi nhận điểm thưởng có thời hạn, đã xảy ra lỗi: %1';
								|ru = 'При выполнении распределения возвратов начислений срочных баллов произошла ошибка: %1';
								|en = 'An error occurred when allocating accrual refunds of fixed-term bonus points: %1'; fa = 'An error occurred when allocating accrual refunds of fixed-term bonus points: %1';
								|it = 'An error occurred when allocating accrual refunds of fixed-term bonus points: %1';
								|pl = 'An error occurred when allocating accrual refunds of fixed-term bonus points: %1';
								|tr = 'Acil puan bakiyelerinin iadelerinin dağıtımını sırasında hata oluştu: %1'");
			MessageText = StrReplace(MessageText,"%1", ErrorText);
			
			WriteLogEvent(NStr("vi = 'Phân bổ điểm thưởng có thời hạn';
								|ru = 'Распределение срочных бонусных баллов';
								|en = 'Allocate fixed-term bonus points'; fa = 'تخصیص امتیازهای پاداش مدت‌دار';
								|it = 'Distribuzione punti bonus urgenti';
								|pl = 'Przydzielenie polnych punktów bonusowych';
								|tr = 'Acil bonus puanların dağıtımı'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , ,
				MessageText);
			Break;
		EndIf;
		
		NumberOfProcessedData = NumberOfProcessedData + ProcessedDocumentsCount;
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, Round(NumberOfProcessedData/100));
	
	Return DistributionIsSuccessful;
	
EndFunction

Function WithdrawReturnsOfAccrualsOfBonusPointsForProcessing(SliceDate, PortionSize = Undefined, ErrorText = "")
	
	QueryResult = RequestResultReturnsOfAccrualsOfBonusPointsForProcessing(SliceDate, PortionSize);
	NumberOfPackages_ = QueryResult.Count();
	
	RequestResultAccrualReturnsForProcessing = QueryResult[NumberOfPackages_-3];
	
	WriteOffReturnsAccrualsOfBonusPoints = QueryResult[NumberOfPackages_-2].Unload();
	WriteOffOfBurntBonusPoints = QueryResult[NumberOfPackages_-1].Unload();
		
	SelectionReturnsOfAccrualsForProcessingLoyaltyProgram = RequestResultAccrualReturnsForProcessing.Select(
		QueryResultIteration.ByGroups, "LoyaltyProgram");
	
	ProcessedDocumentsCount = 0;
	While SelectionReturnsOfAccrualsForProcessingLoyaltyProgram.Next() Do
		
		SelectionReturnsOfAccrualsToBeProcessedByPartner = SelectionReturnsOfAccrualsForProcessingLoyaltyProgram.Select(
			QueryResultIteration.ByGroups, "Partner");
		
		While SelectionReturnsOfAccrualsToBeProcessedByPartner.Next() Do
			
			SelectionReturnsOfAccrualsForProcessingStartDateOfAction = SelectionReturnsOfAccrualsToBeProcessedByPartner.Select(
				QueryResultIteration.ByGroups, "ValidityStartDate");
			
			While SelectionReturnsOfAccrualsForProcessingStartDateOfAction.Next() Do
					
				SelectionOfAccrualReturnsForProcessingDateToWriteOff = SelectionReturnsOfAccrualsForProcessingStartDateOfAction.Select(
					QueryResultIteration.ByGroups, "DateForWriteOff");
				
				While SelectionOfAccrualReturnsForProcessingDateToWriteOff.Next() Do
					
					TheStructureOfTheSearch = New Structure;
					TheStructureOfTheSearch.Insert("LoyaltyProgram");
					TheStructureOfTheSearch.Insert("Partner");
					TheStructureOfTheSearch.Insert("ValidityStartDate");
					TheStructureOfTheSearch.Insert("DateForWriteOff");
					FillPropertyValues(TheStructureOfTheSearch, SelectionOfAccrualReturnsForProcessingDateToWriteOff);
					
					AmountOfUnusedBonusPoints = GetAmountOfUnusedUrgentBonusPoints(
						TheStructureOfTheSearch,
						WriteOffReturnsAccrualsOfBonusPoints,
						WriteOffOfBurntBonusPoints);
					
					BeginTransaction();
					
					Try
						
						SamplingReturnsOfAccrualsForProcessingDetails = SelectionOfAccrualReturnsForProcessingDateToWriteOff.Select();
						
						While SamplingReturnsOfAccrualsForProcessingDetails.Next() Do
							
							DataChanged1 = False;
							
							// we distribute the return of the accrual to the Recorders
							ReturnAmount = SamplingReturnsOfAccrualsForProcessingDetails.ReturnAmount;
							
							DistributeAccrualReturnsToRecorders(
								SamplingReturnsOfAccrualsForProcessingDetails,
								AmountOfUnusedBonusPoints,
								ReturnAmount,
								DataChanged1);
							
							AmountOfUnusedBonusPoints = AmountOfUnusedBonusPoints - ReturnAmount;
							
							If DataChanged1 Then
								ProcessedDocumentsCount = ProcessedDocumentsCount + 1;
							EndIf;
							
						EndDo;
						
						CommitTransaction();
						
					Except
					
						If TransactionActive() Then
							RollbackTransaction();
						EndIf;
						ErrorInfo = ErrorInfo();
						ErrorText = ErrorInfo.Description;
						Break;
						
					EndTry;
					
				EndDo;
					
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Return ProcessedDocumentsCount;
	
EndFunction

Function RequestResultReturnsOfAccrualsOfBonusPointsForProcessing(SliceDate, PortionSize)
	
	QueryTexts = New Array;
	QueryTexts.Add(RequestToRegisterRecordsOfBonusPointsAccrualReturns(PortionSize));
	QueryTexts.Add(RequestValidityPeriodsForBonusPointsReturns());
	QueryTexts.Add(RequestToRegisterRecordsOfBonusPointsAccrual());
	QueryTexts.Add(RequestToRegisterRecordsOfBonusPointsReturnsOfAccrualsForProcessing());
	QueryTexts.Add(RequestToRegisterRecordsForWriteOffOfBurnedBonusPoints());
	QueryTexts.Add(RequestForRegisterRecordingOfWriteOffReturnsAccrualsOfBonusPoints());
	
	MainQueryText = 
	"SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.DateForWriteOff AS DateForWriteOff,
	|	BonusPoints.ReturnAmount AS ReturnAmount,
	|	BonusPoints.Recorder AS Recorder,
	|	BonusPoints.Recorder.Date AS Recorder_Date
	|FROM
	|	BonusPointsRegisteringRecordsReturnsOfAccrualsForProcessing AS BonusPoints
	|
	|ORDER BY
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.DateForWriteOff
	|TOTALS BY
	|	LoyaltyProgram,
	|	Partner,
	|	ValidityStartDate,
	|	DateForWriteOff
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.DateForWriteOff AS DateForWriteOff,
	|	BonusPoints.AmountOfReturnWriteOff AS AmountOfReturnWriteOff
	|FROM
	|	ThereAreRegisterRecordsOfWriteOffOfReturnsOfAccrualsOfBonusPoints AS BonusPoints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.DateForWriteOff AS DateForWriteOff,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.DebitedAmount AS DebitedAmount
	|FROM
	|	ThereAreRegisteredRecordedWriteOffOfBurntBonusPoints AS BonusPoints";
	QueryTexts.Add(MainQueryText);
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("SliceDate", SliceDate);
	Query.SetParameter("RecordTypeReceipt", AccumulationRecordType.Receipt);
	Query.SetParameter("RecordTypeExpense", AccumulationRecordType.Expense);
	
	If PortionSize <> Undefined Then
		Query.Text = StrReplace(Query.Text , "TOP 1000", "FIRST " + Format(PortionSize, "NG=;"));
	EndIf;
	
	Return Query.ExecuteBatch();
	
EndFunction

Function RequestToRegisterRecordsOfBonusPointsAccrualReturns(PortionSize)
	
	QueryText = "
	|SELECT TOP 1
	|	BonusPoints.Period AS Period
	|INTO SelectionStart
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND BonusPoints.DateToProcess >= &SliceDate
	|
	|ORDER BY
	|	Period
	|
	|INDEX BY
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT TOP 1000
	|	CASE
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.Accrued < 0
	|				AND BonusPoints.ToWriteOff = 0
	|			THEN ""AccrualReturn""
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.ToWriteOff < 0
	|				AND BonusPoints.Accrued = 0
	|			THEN ""ReturnOfAccrualsWriteOff""
	|		ELSE """"
	|	END AS OperationKind,
	|	BonusPoints.Period AS Period,
	|	BonusPoints.RecordType AS RecordType,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.Accrued) AS Accrued,
	|	SUM(BonusPoints.ToWriteOff) AS ToWriteOff,
	|	SUM(BonusPoints.Reserved) AS Reserved,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.Recorder AS Recorder,
	|	MAX(BonusPoints.DateToProcess) AS DateToProcess
	|INTO BonusPointsRegisteringRecordsAccrualReturnsSeparately
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|	INNER JOIN SelectionStart AS SelectionStart
	|	ON BonusPoints.Period >= SelectionStart.Period
	|WHERE
	|	BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND (BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.Accrued < 0
	|				AND BonusPoints.ToWriteOff = 0
	|			OR BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.ToWriteOff < 0
	|				AND BonusPoints.Accrued = 0)
	|
	|GROUP BY
	|	CASE
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.Accrued < 0
	|				AND BonusPoints.ToWriteOff = 0
	|			THEN ""AccrualReturn""
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.ToWriteOff < 0
	|				AND BonusPoints.Accrued = 0
	|			THEN ""ReturnOfAccrualsWriteOff""
	|		ELSE """"
	|	END,
	|	BonusPoints.Period,
	|	BonusPoints.Recorder,
	|	BonusPoints.RecordType,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate
	|
	|INDEX BY
	|	Recorder,
	|	RecordType,
	|	Accrued,
	|	ToWriteOff
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPointsDeduction.Period AS DateForWriteOff,
	|	-BonusPoints.Accrued AS ReturnAmount,
	|	BonusPoints.Recorder AS Recorder
	|INTO BonusPointsRegisteringRecordedAccrualReturns
	|FROM
	|	BonusPointsRegisteringRecordsAccrualReturnsSeparately AS BonusPoints
	|		INNER JOIN BonusPointsRegisteringRecordsAccrualReturnsSeparately AS BonusPointsDeduction
	|		ON BonusPoints.Period = BonusPointsDeduction.ValidityStartDate
	|			AND BonusPoints.Recorder = BonusPointsDeduction.Recorder
	|			AND BonusPoints.RecordType = BonusPointsDeduction.RecordType
	|			AND BonusPoints.LoyaltyProgram = BonusPointsDeduction.LoyaltyProgram
	|			AND BonusPoints.Partner = BonusPointsDeduction.Partner
	|			AND BonusPoints.Period = BonusPointsDeduction.ValidityStartDate
	|			AND (BonusPoints.OperationKind = ""AccrualReturn"")
	|			AND (BonusPointsDeduction.OperationKind = ""ReturnOfAccrualsWriteOff"")
	|WHERE
	|	BonusPointsDeduction.Period <> DATETIME(1, 1, 1)
	|	AND BonusPoints.ValidityStartDate <> DATETIME(1, 1, 1)
	|";
	
	If PortionSize <> Undefined Then
		QueryText = StrReplace(QueryText , "TOP 1000", "FIRST " + Format(PortionSize, "NG=;"));
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestValidityPeriodsForBonusPointsReturns()
	
	Return "
	|SELECT DISTINCT
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.DateForWriteOff AS DateForWriteOff,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner
	|INTO ValidityPeriodsOfBonusPointsReturns
	|FROM
	|	BonusPointsRegisteringRecordedAccrualReturns AS BonusPoints
	|";
	 
EndFunction

Function RequestToRegisterRecordsOfBonusPointsAccrual()
	
	Return "
	|SELECT
	|	CASE
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.Accrued > 0
	|				AND BonusPoints.ToWriteOff = 0
	|			THEN ""Accrual""
	|		ELSE """"
	|	END AS OperationKind,
	|	BonusPoints.Period AS Period,
	|	BonusPoints.RecordType AS RecordType,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.Accrued) AS Accrued,
	|	SUM(BonusPoints.ToWriteOff) AS ToWriteOff,
	|	SUM(BonusPoints.Reserved) AS Reserved,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.Recorder AS Recorder,
	|	MAX(BonusPoints.DateToProcess) AS DateToProcess
	|INTO SeparateAccrualOfBonusPointsForRegisteringRecords
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|		INNER JOIN ValidityPeriodsOfBonusPointsReturns AS ValidityPeriodsOfBonusPointsReturns
	|		ON BonusPoints.ValidityStartDate = ValidityPeriodsOfBonusPointsReturns.ValidityStartDate
	|			AND BonusPoints.LoyaltyProgram = ValidityPeriodsOfBonusPointsReturns.LoyaltyProgram
	|			AND BonusPoints.Partner = ValidityPeriodsOfBonusPointsReturns.Partner
	|WHERE
	|	BonusPoints.RecordType = &RecordTypeReceipt
	|	AND BonusPoints.Accrued > 0
	|	AND BonusPoints.ToWriteOff = 0
	|
	|GROUP BY
	|	CASE
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.Accrued > 0
	|				AND BonusPoints.ToWriteOff = 0
	|			THEN ""Accrual""
	|		ELSE """"
	|	END,
	|	BonusPoints.Period,
	|	BonusPoints.Recorder,
	|	BonusPoints.RecordType,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.ToWriteOff > 0
	|				AND BonusPoints.Accrued = 0
	|			THEN ""AccrualWriteOff""
	|		ELSE """"
	|	END,
	|	BonusPoints.Period,
	|	BonusPoints.RecordType,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	SUM(BonusPoints.Accrued),
	|	SUM(BonusPoints.ToWriteOff),
	|	SUM(BonusPoints.Reserved),
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.Recorder,
	|	MAX(BonusPoints.DateToProcess)
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|		INNER JOIN ValidityPeriodsOfBonusPointsReturns AS ValidityPeriodsOfBonusPointsReturns
	|		ON BonusPoints.Period = ValidityPeriodsOfBonusPointsReturns.DateForWriteOff
	|			AND BonusPoints.LoyaltyProgram = ValidityPeriodsOfBonusPointsReturns.LoyaltyProgram
	|			AND BonusPoints.Partner = ValidityPeriodsOfBonusPointsReturns.Partner
	|WHERE
	|	BonusPoints.RecordType = &RecordTypeReceipt
	|	AND BonusPoints.ToWriteOff > 0
	|	AND BonusPoints.Accrued = 0
	|
	|GROUP BY
	|	CASE
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.ToWriteOff > 0
	|				AND BonusPoints.Accrued = 0
	|			THEN ""AccrualWriteOff""
	|		ELSE """"
	|	END,
	|	BonusPoints.Period,
	|	BonusPoints.Recorder,
	|	BonusPoints.RecordType,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate
	|
	|INDEX BY
	|	Recorder,
	|	RecordType,
	|	Accrued,
	|	ToWriteOff
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	CASE
	|		WHEN BonusPoints.DateToProcess = DATETIME(1, 1, 1)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Allocated,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.DateForWriteOff AS DateForWriteOff,
	|	BonusPoints.Accrued AS AccrualAmount,
	|	BonusPoints.Recorder AS Recorder
	|INTO BonusPointsAccrualForRegisteringRecords
	|FROM
	|	(SELECT
	|		BonusPoints.OperationKind AS OperationKind,
	|		BonusPoints.Period AS Period,
	|		BonusPoints.ValidityStartDate AS ValidityStartDate,
	|		BonusPointsDeduction.Period AS DateForWriteOff,
	|		BonusPoints.RecordType AS RecordType,
	|		BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|		BonusPoints.Partner AS Partner,
	|		BonusPoints.Accrued AS Accrued,
	|		BonusPointsDeduction.ToWriteOff AS ToWriteOff,
	|		BonusPoints.Reserved AS Reserved,
	|		BonusPoints.Recorder AS Recorder,
	|		BonusPoints.DateToProcess AS DateToProcess
	|	FROM
	|		SeparateAccrualOfBonusPointsForRegisteringRecords AS BonusPoints
	|			INNER JOIN SeparateAccrualOfBonusPointsForRegisteringRecords AS BonusPointsDeduction
	|			ON BonusPoints.Recorder = BonusPointsDeduction.Recorder
	|				AND BonusPoints.LoyaltyProgram = BonusPointsDeduction.LoyaltyProgram
	|				AND BonusPoints.Partner = BonusPointsDeduction.Partner
	|				AND BonusPoints.Period = BonusPointsDeduction.ValidityStartDate
	|				AND BonusPoints.RecordType = BonusPointsDeduction.RecordType
	|				AND (BonusPoints.OperationKind = ""Accrual"")
	|				AND (BonusPointsDeduction.Period <> BonusPointsDeduction.ValidityStartDate)) AS BonusPoints
	|		INNER JOIN ValidityPeriodsOfBonusPointsReturns AS ValidityPeriodsOfBonusPointsReturns
	|		ON BonusPoints.LoyaltyProgram = ValidityPeriodsOfBonusPointsReturns.LoyaltyProgram
	|			AND BonusPoints.Partner = ValidityPeriodsOfBonusPointsReturns.Partner
	|			AND BonusPoints.ValidityStartDate = ValidityPeriodsOfBonusPointsReturns.ValidityStartDate
	|			AND BonusPoints.DateForWriteOff = ValidityPeriodsOfBonusPointsReturns.DateForWriteOff
	|";
	
EndFunction

Function RequestToRegisterRecordsOfBonusPointsReturnsOfAccrualsForProcessing()
	
	Return "
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.DateForWriteOff AS DateForWriteOff,
	|	SUM(-BonusPoints.Sum) AS ReturnAmount
	|INTO PeriodsOfReturnsOfAccrualsForProcessing
	|FROM
	|	(SELECT
	|		BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|		BonusPoints.Partner AS Partner,
	|		BonusPoints.ValidityStartDate AS ValidityStartDate,
	|		BonusPoints.DateForWriteOff AS DateForWriteOff,
	|		-BonusPoints.ReturnAmount AS Sum
	|	FROM
	|		BonusPointsRegisteringRecordedAccrualReturns AS BonusPoints
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BonusPoints.LoyaltyProgram,
	|		BonusPoints.Partner,
	|		BonusPoints.ValidityStartDate,
	|		BonusPoints.DateForWriteOff,
	|		BonusPoints.AccrualAmount
	|	FROM
	|		BonusPointsAccrualForRegisteringRecords AS BonusPoints
	|	WHERE
	|		BonusPoints.Allocated = FALSE) AS BonusPoints
	|
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.DateForWriteOff
	|
	|HAVING
	|	SUM(-BonusPoints.Sum) > 0
	|;
    |
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.DateForWriteOff AS DateForWriteOff,
	|	BonusPoints.ReturnAmount AS ReturnAmount,
	|	BonusPoints.Recorder AS Recorder
	|INTO BonusPointsRegisteringRecordsReturnsOfAccrualsForProcessing
	|FROM
	|	BonusPointsRegisteringRecordedAccrualReturns AS BonusPoints
	|	INNER JOIN PeriodsOfReturnsOfAccrualsForProcessing AS PeriodsOfReturnsOfAccrualsForProcessing
	|	ON BonusPoints.LoyaltyProgram = PeriodsOfReturnsOfAccrualsForProcessing.LoyaltyProgram
	|		AND BonusPoints.Partner = PeriodsOfReturnsOfAccrualsForProcessing.Partner
	|		AND BonusPoints.ValidityStartDate = PeriodsOfReturnsOfAccrualsForProcessing.ValidityStartDate
	|		AND BonusPoints.DateForWriteOff = PeriodsOfReturnsOfAccrualsForProcessing.DateForWriteOff
	|";
	
EndFunction

Function RequestToRegisterRecordsForWriteOffOfBurnedBonusPoints()
	
	Return "
	|SELECT
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.Period AS DateForWriteOff,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(-BonusPoints.Accrued) AS DebitedAmount
	|INTO ThereAreRegisteredRecordedWriteOffOfBurntBonusPoints
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|		INNER JOIN ValidityPeriodsOfBonusPointsReturns AS ValidityPeriodsOfBonusPointsReturns
	|		ON BonusPoints.LoyaltyProgram = ValidityPeriodsOfBonusPointsReturns.LoyaltyProgram
	|			AND BonusPoints.Partner = ValidityPeriodsOfBonusPointsReturns.Partner
	|			AND BonusPoints.Period = ValidityPeriodsOfBonusPointsReturns.DateForWriteOff
	|			AND BonusPoints.ValidityStartDate = ValidityPeriodsOfBonusPointsReturns.ValidityStartDate
	|WHERE
	|	BonusPoints.RecordType = &RecordTypeReceipt
	|	AND BonusPoints.Accrued < 0
	|	AND BonusPoints.ToWriteOff < 0
	|
	|GROUP BY
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.Period,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner
	|";
	
EndFunction

Function RequestForRegisterRecordingOfWriteOffReturnsAccrualsOfBonusPoints()
	
	Return 
	"SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.Period AS DateForWriteOff,
	|	SUM(BonusPoints.Accrued) AS AmountOfReturnWriteOff
	|INTO ThereAreRegisterRecordsOfWriteOffOfReturnsOfAccrualsOfBonusPoints
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|		INNER JOIN ValidityPeriodsOfBonusPointsReturns AS ValidityPeriodsOfBonusPointsReturns
	|		ON BonusPoints.LoyaltyProgram = ValidityPeriodsOfBonusPointsReturns.LoyaltyProgram
	|			AND BonusPoints.Partner = ValidityPeriodsOfBonusPointsReturns.Partner
	|			AND BonusPoints.ValidityStartDate = ValidityPeriodsOfBonusPointsReturns.ValidityStartDate
	|			AND BonusPoints.Period = ValidityPeriodsOfBonusPointsReturns.DateForWriteOff
	|WHERE
	|	BonusPoints.RecordType = &RecordTypeReceipt
	|	AND BonusPoints.Accrued > 0
	|	AND BonusPoints.ToWriteOff > 0
	|	AND BonusPoints.DateToProcess = DATETIME(1, 1, 1)
	|
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.Period";
	
EndFunction

Procedure DistributeAccrualReturnsToRecorders(ReturnOfAccrualToProcessingOfPart,
	AmountOfUnusedBonusPoints, ReturnAmount, DataChanged1)
	
	AmountToPayment = 0;
	If ReturnAmount > AmountOfUnusedBonusPoints Then
		If AmountOfUnusedBonusPoints <= 0 Then
			AmountToPayment = ReturnAmount;
		Else
			AmountToPayment = ReturnAmount - AmountOfUnusedBonusPoints;
		EndIf;
	EndIf;
	
	Block = New DataLock;
	
	LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
	LockItem.SetValue("Recorder", ReturnOfAccrualToProcessingOfPart.Recorder);
	
	Block.Lock();
	
	SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
	SetOfPHEntriesBonusPoints.Filter.Recorder.Value = ReturnOfAccrualToProcessingOfPart.Recorder;
	SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
	SetOfPHEntriesBonusPoints.Read();
	
	// Clear the "Date for processing" Attribute in the existing Recorders movements, since the return
	// is distributed of operation at the end (debited or converted into an expense)
	For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
		
		If StringRecordsetPHBonusPoints.LoyaltyProgram = ReturnOfAccrualToProcessingOfPart.LoyaltyProgram
			And StringRecordsetPHBonusPoints.Partner = ReturnOfAccrualToProcessingOfPart.Partner
			And ((StringRecordsetPHBonusPoints.Period = ReturnOfAccrualToProcessingOfPart.ValidityStartDate
					And StringRecordsetPHBonusPoints.ValidityStartDate = ReturnOfAccrualToProcessingOfPart.ValidityStartDate)
				Or (StringRecordsetPHBonusPoints.Period = ReturnOfAccrualToProcessingOfPart.DateForWriteOff
					And StringRecordsetPHBonusPoints.ValidityStartDate = ReturnOfAccrualToProcessingOfPart.ValidityStartDate)) Then
			
			StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
			
			DataChanged1 = True;
		EndIf;
		
	EndDo;
	
	// We register the write-off of returned bonus points not used by the buyer before
	StringRecordsetPHBonusPoints = SetOfPHEntriesBonusPoints.Add();
	FillPropertyValues(StringRecordsetPHBonusPoints, ReturnOfAccrualToProcessingOfPart);
	
	StringRecordsetPHBonusPoints.RecordType = AccumulationRecordType.Receipt;
	StringRecordsetPHBonusPoints.Period = ReturnOfAccrualToProcessingOfPart.DateForWriteOff;
	StringRecordsetPHBonusPoints.Accrued = ReturnAmount;
	StringRecordsetPHBonusPoints.ToWriteOff = ReturnAmount;
	
	// We register the conversion of the returned bonus points into payment (we convert it into an expense), since
	// the bonus points were used earlier
	If AmountToPayment > 0 Then
		StringRecordsetPHBonusPoints = SetOfPHEntriesBonusPoints.Add();
		FillPropertyValues(StringRecordsetPHBonusPoints, ReturnOfAccrualToProcessingOfPart);
		
		StringRecordsetPHBonusPoints.RecordType = AccumulationRecordType.Expense;
		StringRecordsetPHBonusPoints.Period = ReturnOfAccrualToProcessingOfPart.Recorder_Date;
		StringRecordsetPHBonusPoints.Accrued = AmountToPayment;
		StringRecordsetPHBonusPoints.ValidityStartDate = Date(1, 1, 1);
		StringRecordsetPHBonusPoints.DateToProcess = CurrentSessionDate();
		
		DataChanged1 = True;
	EndIf;
	
	SetOfPHEntriesBonusPoints.Write();
	
EndProcedure

Function GetAmountOfUnusedUrgentBonusPoints(TheStructureOfTheSearch,
	WriteOffReturnsAccrualsOfBonusPoints, WriteOffOfBurntBonusPoints)
	
	WriteOffReturnsAccrualsOfBonusPointsByPeriod
		= WriteOffReturnsAccrualsOfBonusPoints.Copy(TheStructureOfTheSearch);
	AmountOfWriteOffOfReturnsOfAccruals
		= WriteOffReturnsAccrualsOfBonusPointsByPeriod.Total("AmountOfReturnWriteOff");
	
	WriteOffOfBurntBonusPointsByPeriod
		= WriteOffOfBurntBonusPoints.Copy(TheStructureOfTheSearch);
	AmountOfWriteOffOfBurntBonusPoints = WriteOffOfBurntBonusPointsByPeriod.Total("DebitedAmount");
	
	AmountOfUnusedBonusPoints = AmountOfWriteOffOfBurntBonusPoints - AmountOfWriteOffOfReturnsOfAccruals;
	
	Return AmountOfUnusedBonusPoints;
	
EndFunction

#EndRegion

#Region ProcessingReturnOfBonusPoints

Function ProcessBonusPointsPaymentReturns(SliceDate)
	
	DistributionIsSuccessful = True;
	NumberOfProcessedData = 0;
	RepeatProcessing = True;
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"ScheduledJob.AllocateFixedTermBonusPoints.ProcessReturnsOfAccrualsOfBonusPoints_x100");
	
	While RepeatProcessing Do
		ErrorText = "";
		
		ProcessedDocumentsCount = WithdrawBonusPointsPaymentReturnsForProcessing(SliceDate,,ErrorText);
		RepeatProcessing = Not (ProcessedDocumentsCount = 0);
		
		If ValueIsFilled(ErrorText) Then
			DistributionIsSuccessful = False;
			MessageText = NStr("vi = 'Khi phân bổ các khoản hoàn trả thanh toán bằng điểm thưởng, đã xảy ra lỗi: %1';
								|ru = 'При выполнении распределения возвратов оплат бонусными баллами произошла ошибка: %1';
								|en = 'An error occurred while allocating refunds of bonus point payments: %1'; fa = 'An error occurred while allocating refunds of bonus point payments: %1';
								|it = 'An error occurred while allocating refunds of bonus point payments: %1';
								|pl = 'An error occurred while allocating refunds of bonus point payments: %1';
								|tr = 'Bonus puanların iadelerinin dağıtımı sırasında hata oluştu: %1'");
			MessageText = StrReplace(MessageText,"%1", ErrorText);
			
			WriteLogEvent(NStr("vi = 'Phân bổ điểm thưởng có thời hạn';
								|ru = 'Распределение срочных бонусных баллов';
								|en = 'Allocate fixed-term bonus points'; fa = 'تخصیص امتیازهای پاداش مدت‌دار';
								|it = 'Distribuzione punti bonus urgenti';
								|pl = 'Przydzielenie polnych punktów bonusowych';
								|tr = 'Acil bonus puanların dağıtımı'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , ,
				MessageText);
			Break;
		EndIf;
		
		NumberOfProcessedData = NumberOfProcessedData + ProcessedDocumentsCount;
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, Round(NumberOfProcessedData/100));
	
	Return DistributionIsSuccessful;
	
EndFunction

Function WithdrawBonusPointsPaymentReturnsForProcessing(SliceDate, PortionSize = Undefined, ErrorText = "")
	
	QueryResult = ResultOfRequestReturnsOfPaymentsWithBonusPointsForProcessing(SliceDate, PortionSize);
	NumberOfPackages_ = QueryResult.Count();
	
	RequestResultPaymentReturnPeriodsWithBonusPointsForProcessing = QueryResult[NumberOfPackages_-6];
	
	ReturnsOfPaymentsWithBonusPointsForProcessing = QueryResult[NumberOfPackages_-5].Unload();
	DistributedPaymentsWithBonusPoints = QueryResult[NumberOfPackages_-4].Unload();
	DistributedPaymentsWithPerpetualBonusPoints = QueryResult[NumberOfPackages_-3].Unload();
	WriteOffOfBurntBonusPoints = QueryResult[NumberOfPackages_-2].Unload();
	PartiallyDistributedBonusPointsPayments = QueryResult[NumberOfPackages_-1].Unload();
	
	SamplingReturnPaymentPeriodsForProcessingLoyaltyProgram = RequestResultPaymentReturnPeriodsWithBonusPointsForProcessing.Select(
		QueryResultIteration.ByGroups, "LoyaltyProgram");
	
	ProcessedDocumentsCount = 0;
	While SamplingReturnPaymentPeriodsForProcessingLoyaltyProgram.Next() Do
		
		SamplingPaymentReturnPeriodsForProcessingPartner = SamplingReturnPaymentPeriodsForProcessingLoyaltyProgram.Select(
			QueryResultIteration.ByGroups, "Partner");
		
		While SamplingPaymentReturnPeriodsForProcessingPartner.Next() Do
			
			SamplingPeriodsOfReturnsOfPaymentsForProcessingDetails = SamplingPaymentReturnPeriodsForProcessingPartner.Select();
			
			While SamplingPeriodsOfReturnsOfPaymentsForProcessingDetails.Next() Do
					
					ReturnAmountToDistribution = SamplingPeriodsOfReturnsOfPaymentsForProcessingDetails.ReturnAmount;
					
					BeginTransaction();
					
					Try
						
						DataChanged1 = False;
						
						TheStructureOfTheSearch = New Structure;
						TheStructureOfTheSearch.Insert("LoyaltyProgram");
						TheStructureOfTheSearch.Insert("Partner");
						TheStructureOfTheSearch.Insert("Period");
						FillPropertyValues(TheStructureOfTheSearch, SamplingPeriodsOfReturnsOfPaymentsForProcessingDetails);
						
						// Get Recorders for the period and the amount of return for distribution
						RecordersForDistribution = ReturnsOfPaymentsWithBonusPointsForProcessing.Copy(TheStructureOfTheSearch);
						
						// Determine whether the buyer would have spent them if the return had occurred before the distribution of payment for the
						// accrual of urgent bonus points. If he hadn't spent it, don't give him points back
						DoNotRefundBonusPoints = False;
						If WriteOffOfBurntBonusPoints.FindRows(TheStructureOfTheSearch).Count() > 0 Then
							DoNotRefundBonusPoints = True;
						EndIf;
						
						// Get unlimited bonus points that were used to pay
						DistributedPerpetualReturnPayments = DistributedPaymentsWithPerpetualBonusPoints.Copy(TheStructureOfTheSearch);
						AmountOfPaymentInPerpetuity = Min(DistributedPerpetualReturnPayments.Total("PayAmount"), ReturnAmountToDistribution);
						
						// Get urgent bonus points that have been used for payment
						DistributedReturnPayments = DistributedPaymentsWithBonusPoints.Copy(TheStructureOfTheSearch);
						DistributedReturnPayments.Sort("DateForWriteOff");
						
						// To decide whether to withdraw a return of payment from processing or a return of payment should be withdrawn after
						// the distribution of payment and accrual
						ToWithdrawReturnOfPaymentFromProcessing = True;
						If PartiallyDistributedBonusPointsPayments.FindRows(TheStructureOfTheSearch).Count() > 0 Then
							ToWithdrawReturnOfPaymentFromProcessing = False;
						EndIf;
						
						// Get a Recorders return payment for distribution
						For Each PaymentReturnRecorders In RecordersForDistribution Do
							
							If DoNotRefundBonusPoints Then
								
								DistributeReturnsOfPaymentsToRecordersWriteOff(PaymentReturnRecorders, DataChanged1);
								
							Else
								
								ContinueDistribution = DistributeReturnsOfPaymentsToRecordersConversionToPayment(
									PaymentReturnRecorders,
									DistributedReturnPayments,
									ToWithdrawReturnOfPaymentFromProcessing,
									ReturnAmountToDistribution,
									AmountOfPaymentInPerpetuity,
									DataChanged1);
								
								If Not ContinueDistribution Then
									Break;
								EndIf;
								
							EndIf;
							
						EndDo;
						
						If DataChanged1 Then
							ProcessedDocumentsCount = ProcessedDocumentsCount + 1;
						EndIf;
						
						CommitTransaction();
						
					Except
					
						If TransactionActive() Then
							RollbackTransaction();
						EndIf;
						ErrorInfo = ErrorInfo();
						ErrorText = ErrorInfo.Description;
						Break;
						
					EndTry;
					
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Return ProcessedDocumentsCount;
	
EndFunction

Function ResultOfRequestReturnsOfPaymentsWithBonusPointsForProcessing(SliceDate, PortionSize)
	
	QueryTexts = New Array;
	QueryTexts.Add(RequestToRegisterRecordsOfPaymentReturnsWithBonusPoints(PortionSize));
	QueryTexts.Add(RequestPaymentReturnPeriodsWithBonusPoints());
	QueryTexts.Add(RequestToRegisterRecordsOfPaymentsWithBonusPoints());
	QueryTexts.Add(PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing());
	QueryTexts.Add(RequestToRegisterRecordsOfPaymentReturnsWithBonusPointsToBeProcessed());
	QueryTexts.Add(RequestToRegisterRecordsOfDistributedPaymentsWithBonusPoints());
	QueryTexts.Add(RequestToRegisterRecordsOfPartiallyDistributedPaymentsWithBonusPoints());
	QueryTexts.Add(RequestToRegisterRecordsOfDistributedPaymentsWithPerpetualBonusPoints());
	QueryTexts.Add(RequestToRegisterRecordsForWriteOffOfBurntBonusPointsReturnOfPayment());
	
	MainQueryText = "
	|SELECT
	|	BonusPoints.Period AS Period,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.ReturnAmount AS ReturnAmount
	|FROM
	|	PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing AS BonusPoints
	|
	|ORDER BY
	|	Period
	|TOTALS BY
	|	LoyaltyProgram,
	|	Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.Period AS Period,
	|	BonusPoints.Recorder AS Recorder,
	|	BonusPoints.ReturnDate AS ReturnDate,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.ReturnAmount AS ReturnAmount
	|FROM
	|	PaymentReturnsWithBonusPointsAreRegisteredRecordedForProcessing AS BonusPoints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.DateForWriteOff AS DateForWriteOff,
	|	BonusPoints.ActionPeriod AS ActionPeriod,
	|	BonusPoints.Period AS Period,
	|	BonusPoints.ReturnAmount AS ReturnAmount
	|FROM
	|	DistributedPaymentsRegisteredRecordsWithBonusPoints AS BonusPoints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.Period AS Period,
	|	BonusPoints.PayAmount AS PayAmount
	|FROM
	|	DistributedPaymentsRegisteredRecordsWithPerpetualBonusPoints AS BonusPoints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.Period AS Period,
	|	BonusPoints.AmountOfAccrualWriteOff AS AmountOfAccrualWriteOff
	|FROM
	|	ThereAreRegisteredRecordedWriteOffOfBurntBonusPoints AS BonusPoints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.Period AS Period,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.ToWriteOff AS ToWriteOff
	|FROM
	|	RegisterRecordedPartiallyDistributedPaymentsWithBonusPoints AS BonusPoints
	|";
	QueryTexts.Add(MainQueryText);
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("SliceDate", SliceDate);
	Query.SetParameter("RecordTypeReceipt", AccumulationRecordType.Receipt);
	Query.SetParameter("RecordTypeExpense", AccumulationRecordType.Expense);
	
	If PortionSize <> Undefined Then
		Query.Text = StrReplace(Query.Text , "TOP 1000", "FIRST " + Format(PortionSize, "NG=;"));
	EndIf;
	
	Return Query.ExecuteBatch();
	
EndFunction

Function RequestToRegisterRecordsOfPaymentReturnsWithBonusPoints(PortionSize)
	
	QueryText = "
	|SELECT TOP 1
	|	BonusPoints.Period AS Period
	|INTO SelectionStart
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND BonusPoints.DateToProcess >= &SliceDate
	|
	|ORDER BY
	|	Period
	|
	|INDEX BY
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT TOP 1000
	|	CASE
	|		WHEN BonusPoints.RecordType = &RecordTypeExpense
	|				AND BonusPoints.Accrued < 0
	|				AND BonusPoints.ToWriteOff = 0
	|			THEN ""RefundOfPayment""
	|		ELSE """"
	|	END AS OperationKind,
	|	BonusPoints.Period AS Period,
	|	BonusPoints.RecordType AS RecordType,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.Accrued) AS Accrued,
	|	SUM(BonusPoints.ToWriteOff) AS ToWriteOff,
	|	SUM(BonusPoints.Reserved) AS Reserved,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.Recorder AS Recorder,
	|	MAX(BonusPoints.DateToProcess) AS DateToProcess
	|INTO PaymentReturnsAreRegisteredRecordedWithBonusPoints
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|		INNER JOIN SelectionStart AS SelectionStart
	|		ON BonusPoints.Period >= SelectionStart.Period
	|WHERE
	|	BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND BonusPoints.RecordType = &RecordTypeExpense
	|	AND BonusPoints.Accrued < 0
	|	AND BonusPoints.ToWriteOff = 0
	|
	|GROUP BY
	|	CASE
	|		WHEN BonusPoints.RecordType = &RecordTypeExpense
	|				AND BonusPoints.Accrued < 0
	|				AND BonusPoints.ToWriteOff = 0
	|			THEN ""RefundOfPayment""
	|		ELSE """"
	|	END,
	|	BonusPoints.Period,
	|	BonusPoints.Recorder,
	|	BonusPoints.RecordType,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate
	|";
	
	If PortionSize <> Undefined Then
		QueryText = StrReplace(QueryText , "TOP 1000", "FIRST " + Format(PortionSize, "NG=;"));
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestPaymentReturnPeriodsWithBonusPoints()
	
	Return "
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.Period AS Period
	|INTO PeriodsOfReturnsOfPaymentWithBonusPoints
	|FROM
	|	PaymentReturnsAreRegisteredRecordedWithBonusPoints AS BonusPoints
	|
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.Period
	|";
	
EndFunction

Function RequestToRegisterRecordsOfPaymentsWithBonusPoints()
	
	Return "
	|SELECT
	|	BonusPoints.Period AS Period,
	|	BonusPoints.Recorder AS Recorder,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.Accrued) AS PayAmount,
	|	CASE
	|		WHEN BonusPoints.DateToProcess = DATETIME(1, 1, 1)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Allocated
	|INTO PaymentRegisteringRecordsWithBonusPoints
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|		INNER JOIN PeriodsOfReturnsOfPaymentWithBonusPoints AS PeriodsOfReturnsOfPaymentWithBonusPoints
	|		ON BonusPoints.Period = PeriodsOfReturnsOfPaymentWithBonusPoints.Period
	|			AND BonusPoints.LoyaltyProgram = PeriodsOfReturnsOfPaymentWithBonusPoints.LoyaltyProgram
	|			AND BonusPoints.Partner = PeriodsOfReturnsOfPaymentWithBonusPoints.Partner
	|WHERE
	|	BonusPoints.RecordType = &RecordTypeExpense
	|	AND BonusPoints.Accrued > 0
	|	AND BonusPoints.ToWriteOff = 0
	|
	|GROUP BY
	|	BonusPoints.Period,
	|	BonusPoints.Recorder,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	CASE
	|		WHEN BonusPoints.DateToProcess = DATETIME(1, 1, 1)
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|";
	
EndFunction

Function PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing()
	
	Return "
	|SELECT
	|	BonusPoints.Period AS Period,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(-BonusPoints.ReturnAmount) AS ReturnAmount
	|INTO PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing
	|FROM
	|	(SELECT
	|		BonusPoints.Period AS Period,
	|		BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|		BonusPoints.Partner AS Partner,
	|		BonusPoints.Accrued AS ReturnAmount
	|	FROM
	|		PaymentReturnsAreRegisteredRecordedWithBonusPoints AS BonusPoints
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BonusPoints.Period,
	|		BonusPoints.LoyaltyProgram,
	|		BonusPoints.Partner,
	|		BonusPoints.PayAmount
	|	FROM
	|		PaymentRegisteringRecordsWithBonusPoints AS BonusPoints
	|	WHERE
	|		BonusPoints.Allocated = FALSE) AS BonusPoints
	|
	|GROUP BY
	|	BonusPoints.Period,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner
	|
	|HAVING
	|	SUM(-BonusPoints.ReturnAmount) > 0
	|";
	
EndFunction

Function RequestToRegisterRecordsOfPaymentReturnsWithBonusPointsToBeProcessed()
	
	Return "
	|SELECT
	|	BonusPoints.Period AS Period,
	|	BonusPoints.Recorder AS Recorder,
	|	BEGINOFPERIOD(BonusPoints.Recorder.DATE, DAY) AS ReturnDate,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(-BonusPoints.Accrued) AS ReturnAmount
	|INTO PaymentReturnsWithBonusPointsAreRegisteredRecordedForProcessing
	|FROM
	|	PaymentReturnsAreRegisteredRecordedWithBonusPoints AS BonusPoints
	|		INNER JOIN PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing AS PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing
	|		ON BonusPoints.Period = PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing.Period
	|			AND BonusPoints.LoyaltyProgram = PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing.LoyaltyProgram
	|			AND BonusPoints.Partner = PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing.Partner
	|
	|GROUP BY
	|	BonusPoints.Period,
	|	BonusPoints.Recorder,
	|	BEGINOFPERIOD(BonusPoints.Recorder.DATE, DAY),
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner
	|";
	
EndFunction

Function RequestToRegisterRecordsOfDistributedPaymentsWithBonusPoints()
	
	Return "
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.Period AS DateForWriteOff,
	|	DATEDIFF(BonusPoints.ValidityStartDate, BonusPoints.Period, DAY) AS ActionPeriod,
	|	PaymentRegisteringRecordsWithBonusPoints.Period,
	|	SUM(BonusPoints.ToWriteOff) AS ReturnAmount
	|INTO DistributedPaymentsRegisteredRecordsWithBonusPoints
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|		INNER JOIN PaymentRegisteringRecordsWithBonusPoints AS PaymentRegisteringRecordsWithBonusPoints
	|		ON BonusPoints.Recorder = PaymentRegisteringRecordsWithBonusPoints.Recorder
	|			AND BonusPoints.LoyaltyProgram = PaymentRegisteringRecordsWithBonusPoints.LoyaltyProgram
	|			AND BonusPoints.Partner = PaymentRegisteringRecordsWithBonusPoints.Partner
	|		INNER JOIN PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing AS PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing
	|		ON BonusPoints.LoyaltyProgram = PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing.LoyaltyProgram
	|			AND BonusPoints.Partner = PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing.Partner
	|WHERE
	|	BonusPoints.RecordType = &RecordTypeExpense
	|	AND BonusPoints.Accrued = 0
	|	AND BonusPoints.ToWriteOff > 0
	|
	|GROUP BY
	|	BonusPoints.Period,
	|	PaymentRegisteringRecordsWithBonusPoints.Period,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate,
	|	DATEDIFF(BonusPoints.ValidityStartDate, BonusPoints.Period, DAY)
	|";
	
EndFunction

Function RequestToRegisterRecordsOfPartiallyDistributedPaymentsWithBonusPoints()
	
	Return "
	|SELECT
	|	BEGINOFPERIOD(BonusPoints.Recorder.Date, DAY) AS Period,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.ToWriteOff) AS ToWriteOff
	|INTO RegisterRecordedPartiallyDistributedPaymentsWithBonusPoints
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	(BonusPoints.Recorder, BonusPoints.LoyaltyProgram, BonusPoints.Partner) IN
	|			(SELECT DISTINCT
	|				BonusPoints.Recorder AS Recorder,
	|				BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|				BonusPoints.Partner AS Partner
	|			FROM
	|				PaymentRegisteringRecordsWithBonusPoints AS BonusPoints
	|			WHERE
	|				BonusPoints.Allocated = FALSE)
	|
	|GROUP BY
	|	BEGINOFPERIOD(BonusPoints.Recorder.Date, DAY),
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner
	|
	|HAVING
	|	SUM(BonusPoints.ToWriteOff) > 0
	|";
	
EndFunction

Function RequestToRegisterRecordsOfDistributedPaymentsWithPerpetualBonusPoints()
	
	Return "
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BEGINOFPERIOD(BonusPoints.Recorder.Date, DAY) AS Period,
	|	SUM(BonusPoints.PayAmount) AS PayAmount
	|INTO DistributedPaymentsRegisteredRecordsWithPerpetualBonusPoints
	|FROM
	|	(SELECT
	|		BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|		BonusPoints.Partner AS Partner,
	|		BonusPoints.Recorder AS Recorder,
	|		SUM(BonusPoints.PayAmount) AS PayAmount
	|	FROM
	|		(SELECT
	|			BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|			BonusPoints.Partner AS Partner,
	|			BonusPoints.Recorder AS Recorder,
	|			BonusPoints.Accrued - BonusPoints.ToWriteOff AS PayAmount
	|		FROM
	|			AccumulationRegister.BonusPoints AS BonusPoints
	|				INNER JOIN PaymentRegisteringRecordsWithBonusPoints AS PaymentRegisteringRecordsWithBonusPoints
	|				ON BonusPoints.Recorder = PaymentRegisteringRecordsWithBonusPoints.Recorder
	|					AND BonusPoints.LoyaltyProgram = PaymentRegisteringRecordsWithBonusPoints.LoyaltyProgram
	|					AND BonusPoints.Partner = PaymentRegisteringRecordsWithBonusPoints.Partner
	|				INNER JOIN PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing AS PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing
	|				ON BonusPoints.LoyaltyProgram = PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing.LoyaltyProgram
	|					AND BonusPoints.Partner = PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing.Partner
	|		WHERE
	|			BonusPoints.DateToProcess = DATETIME(1, 1, 1)
	|			AND BonusPoints.RecordType = &RecordTypeExpense
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|			BonusPoints.Partner AS Partner,
	|			BonusPoints.Recorder AS Recorder,
	|			-BonusPoints.ToWriteOff AS PayAmount
	|		FROM
	|			AccumulationRegister.BonusPoints AS BonusPoints
	|				INNER JOIN PaymentRegisteringRecordsWithBonusPoints AS PaymentRegisteringRecordsWithBonusPoints
	|				ON BonusPoints.Recorder = PaymentRegisteringRecordsWithBonusPoints.Recorder
	|					AND BonusPoints.LoyaltyProgram = PaymentRegisteringRecordsWithBonusPoints.LoyaltyProgram
	|					AND BonusPoints.Partner = PaymentRegisteringRecordsWithBonusPoints.Partner
	|				INNER JOIN PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing AS PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing
	|				ON BonusPoints.LoyaltyProgram = PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing.LoyaltyProgram
	|					AND BonusPoints.Partner = PeriodsOfReturnsOfPaymentWithBonusPointsForProcessing.Partner
	|		WHERE
	|			BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|			AND BonusPoints.RecordType = &RecordTypeExpense
	|			AND BonusPoints.ToWriteOff > 0) AS BonusPoints
	|	
	|	GROUP BY
	|		BonusPoints.Recorder,
	|		BonusPoints.LoyaltyProgram,
	|		BonusPoints.Partner
	|	
	|	HAVING
	|		SUM(BonusPoints.PayAmount) > 0) AS BonusPoints
	|
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BEGINOFPERIOD(BonusPoints.Recorder.Date, DAY)
	|";
	
EndFunction

Function RequestToRegisterRecordsForWriteOffOfBurntBonusPointsReturnOfPayment()
	
	Return "
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	PaymentsWithBonusPoints.Period AS Period,
	|	SUM(-BonusPoints.Accrued) AS AmountOfAccrualWriteOff
	|INTO ThereAreRegisteredRecordedWriteOffOfBurntBonusPoints
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|		INNER JOIN DistributedPaymentsRegisteredRecordsWithBonusPoints AS PaymentsWithBonusPoints
	|		ON BonusPoints.LoyaltyProgram = PaymentsWithBonusPoints.LoyaltyProgram
	|			AND BonusPoints.Partner = PaymentsWithBonusPoints.Partner
	|			AND BonusPoints.ValidityStartDate = PaymentsWithBonusPoints.ValidityStartDate
	|			AND BonusPoints.Period = PaymentsWithBonusPoints.DateForWriteOff
	|WHERE
	|	BonusPoints.RecordType = &RecordTypeReceipt
	|	AND BonusPoints.Accrued < 0
	|	AND BonusPoints.ToWriteOff < 0
	|
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	PaymentsWithBonusPoints.Period
	|";
	
EndFunction

Procedure DistributeReturnsOfPaymentsToRecordersWriteOff(PaymentReturnRecorders, DataChanged1)
	
	Block = New DataLock;
							
	LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
	LockItem.SetValue("Recorder", PaymentReturnRecorders.Recorder);
	
	Block.Lock();
	
	SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
	SetOfPHEntriesBonusPoints.Filter.Recorder.Value = PaymentReturnRecorders.Recorder;
	SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
	SetOfPHEntriesBonusPoints.Read();
	
	For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
		
		If StringRecordsetPHBonusPoints.LoyaltyProgram = PaymentReturnRecorders.LoyaltyProgram
			And StringRecordsetPHBonusPoints.Partner = PaymentReturnRecorders.Partner
			And StringRecordsetPHBonusPoints.Period = PaymentReturnRecorders.Period Then
			
			StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
			
			DataChanged1 = True;
			
		EndIf;
		
	EndDo;
	
	RegisteredRecordsAreStornoForReturnOfPayment = SetOfPHEntriesBonusPoints.Add();
	FillPropertyValues(RegisteredRecordsAreStornoForReturnOfPayment, PaymentReturnRecorders);
	RegisteredRecordsAreStornoForReturnOfPayment.RecordType = AccumulationRecordType.Expense;
	RegisteredRecordsAreStornoForReturnOfPayment.Accrued = PaymentReturnRecorders.ReturnAmount;
	
	SetOfPHEntriesBonusPoints.Write();
	
EndProcedure

Function DistributeReturnsOfPaymentsToRecordersConversionToPayment(PaymentReturnRecorders,
	DistributedReturnPayments, ToWithdrawReturnOfPaymentFromProcessing, ReturnAmountToDistribution, AmountOfPaymentInPerpetuity, DataChanged1)
	
	AmountOfRecorderToBeDistributed = Min(ReturnAmountToDistribution, PaymentReturnRecorders.ReturnAmount);
	AmountOfRecorderToBeDistributedInPerpetuity = Min(AmountOfRecorderToBeDistributed, AmountOfPaymentInPerpetuity);
	AmountOfRecorderToBeDistributedByUrgent = AmountOfRecorderToBeDistributed - AmountOfPaymentInPerpetuity;
	
	Block = New DataLock;
							
	LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
	LockItem.SetValue("Recorder", PaymentReturnRecorders.Recorder);
	
	Block.Lock();
	
	SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
	SetOfPHEntriesBonusPoints.Filter.Recorder.Value = PaymentReturnRecorders.Recorder;
	SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
	SetOfPHEntriesBonusPoints.Read();
	
	If ToWithdrawReturnOfPaymentFromProcessing Then
		
		For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
			
			If StringRecordsetPHBonusPoints.LoyaltyProgram = PaymentReturnRecorders.LoyaltyProgram
				And StringRecordsetPHBonusPoints.Partner = PaymentReturnRecorders.Partner
				And StringRecordsetPHBonusPoints.Period = PaymentReturnRecorders.Period Then
				
				StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
				
				DataChanged1 = True;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// If the refunded payments were allocated to perpetual bonus points, the
	// buyer first needs to return the bonus points as perpetual
	If AmountOfRecorderToBeDistributedInPerpetuity > 0 Then
		// Storno return of payment
		RegisteredRecordsAreStornoForReturnOfPayment = SetOfPHEntriesBonusPoints.Add();
		FillPropertyValues(RegisteredRecordsAreStornoForReturnOfPayment, PaymentReturnRecorders);
		RegisteredRecordsAreStornoForReturnOfPayment.RecordType = AccumulationRecordType.Expense;
		RegisteredRecordsAreStornoForReturnOfPayment.Accrued = AmountOfRecorderToBeDistributedInPerpetuity;
		If Not ToWithdrawReturnOfPaymentFromProcessing Then
			RegisteredRecordsAreStornoForReturnOfPayment.DateToProcess = CurrentSessionDate();
		EndIf;
		
		// Conversion of the amount from the date of payment to the accrual of perpetual bonus points
		RegisteredRecordsAccrualOfPaymentReturn = SetOfPHEntriesBonusPoints.Add();
		FillPropertyValues(RegisteredRecordsAccrualOfPaymentReturn, PaymentReturnRecorders);
		RegisteredRecordsAccrualOfPaymentReturn.RecordType = AccumulationRecordType.Receipt;
		RegisteredRecordsAccrualOfPaymentReturn.Period = BegOfDay(PaymentReturnRecorders.ReturnDate);
		RegisteredRecordsAccrualOfPaymentReturn.Accrued = AmountOfRecorderToBeDistributedInPerpetuity;
		
		AmountOfPaymentInPerpetuity = AmountOfPaymentInPerpetuity - AmountOfRecorderToBeDistributedInPerpetuity;
		
		DataChanged1 = True;
	EndIf;
	
	// If the amount of the return payment remains for distribution and the refunded payments have been distributed to
	// urgent bonus points, the bonus points will be returned to the buyer as urgent with the validity period of
	// the bonus points to which the refunded payment was distributed. The processing priority corresponds
	// to the distribution of payments - priority by the end date of the action.
	If AmountOfRecorderToBeDistributedByUrgent > 0 Then
		
		//these are the consumable data, they decrease as they are distributed
		For Each DistributedPaymentData In DistributedReturnPayments Do
			If DistributedPaymentData.ReturnAmount = 0 Then
				Continue;
			EndIf;
			
			AmountOfDistributedPayment = Min(AmountOfRecorderToBeDistributedByUrgent, DistributedPaymentData.ReturnAmount);
			
			// Storno return of payment
			RegisteredRecordsAreStornoForReturnOfPayment = SetOfPHEntriesBonusPoints.Add();
			FillPropertyValues(RegisteredRecordsAreStornoForReturnOfPayment, PaymentReturnRecorders);
			RegisteredRecordsAreStornoForReturnOfPayment.RecordType = AccumulationRecordType.Expense;
			RegisteredRecordsAreStornoForReturnOfPayment.Accrued = AmountOfDistributedPayment;
			If Not ToWithdrawReturnOfPaymentFromProcessing Then
				RegisteredRecordsAreStornoForReturnOfPayment.DateToProcess = CurrentSessionDate();
			EndIf;
			
			// Conversion of the amount from the date of payment to the accrual of perpetual bonus points
			RegisteredRecordsAccrualOfPaymentReturn = SetOfPHEntriesBonusPoints.Add();
			FillPropertyValues(RegisteredRecordsAccrualOfPaymentReturn, PaymentReturnRecorders);
			RegisteredRecordsAccrualOfPaymentReturn.RecordType = AccumulationRecordType.Receipt;
			RegisteredRecordsAccrualOfPaymentReturn.Period = BegOfDay(PaymentReturnRecorders.ReturnDate);
			RegisteredRecordsAccrualOfPaymentReturn.Accrued = AmountOfDistributedPayment;
			RegisteredRecordsAccrualOfPaymentReturn.ValidityStartDate = BegOfDay(PaymentReturnRecorders.ReturnDate);
			RegisteredRecordsAccrualOfPaymentReturn.DateToProcess = CurrentSessionDate();
			
			RegisteredRecordsAccrualOfPaymentReturn = SetOfPHEntriesBonusPoints.Add();
			FillPropertyValues(RegisteredRecordsAccrualOfPaymentReturn, PaymentReturnRecorders);
			RegisteredRecordsAccrualOfPaymentReturn.RecordType = AccumulationRecordType.Receipt;
			RegisteredRecordsAccrualOfPaymentReturn.Period = BegOfDay(PaymentReturnRecorders.ReturnDate)
				+ DistributedPaymentData.ActionPeriod * 24*60*60;
			RegisteredRecordsAccrualOfPaymentReturn.ToWriteOff = AmountOfDistributedPayment;
			RegisteredRecordsAccrualOfPaymentReturn.ValidityStartDate = BegOfDay(PaymentReturnRecorders.ReturnDate);
			RegisteredRecordsAccrualOfPaymentReturn.DateToProcess = CurrentSessionDate();
			
			AmountOfRecorderToBeDistributedByUrgent = AmountOfRecorderToBeDistributedByUrgent - AmountOfDistributedPayment;
			DistributedPaymentData.ReturnAmount = DistributedPaymentData.ReturnAmount - AmountOfDistributedPayment;
			
			DataChanged1 = True;
			
			If AmountOfRecorderToBeDistributedByUrgent = 0 Then
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
	SetOfPHEntriesBonusPoints.Write();
	
	ReturnAmountToDistribution = ReturnAmountToDistribution
		- AmountOfRecorderToBeDistributedInPerpetuity
		- AmountOfRecorderToBeDistributedByUrgent;
		
	ContinueDistribution = True;
	If ReturnAmountToDistribution = 0 Then
		ContinueDistribution = False;
	EndIf;
	
	Return ContinueDistribution;
	
EndFunction

#EndRegion

#Region DistributionOfDebitedUrgentBonusPointsInStatusForProcessing

Function ProcessPaymentsAndAccrualsOfUrgentBonusPoints(StartDateOfBonusPointsMechanism_2_5)
	
	DistributionIsSuccessful = True;
	
	NumberOfProcessedData = 0;
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"ScheduledJob.AllocateFixedTermBonusPoints.DistributeWriteOffOfUrgentBonusPointsInProcessingStatus_x100");
	
	RepeatDistribution = True;
	While RepeatDistribution Do
		ErrorText = "";
		
		ProcessedDocumentsCount = DistributeWriteOffOfUrgentBonusPointsInStatusForProcessing(
			StartDateOfBonusPointsMechanism_2_5,,
			ErrorText);
		NumberOfProcessedData = NumberOfProcessedData + ProcessedDocumentsCount;
		
		RepeatDistribution = Not (ProcessedDocumentsCount = 0);
		If ValueIsFilled(ErrorText) Then
			DistributionIsSuccessful = False;
			MessageText = NStr("vi = 'Khi thực hiện phân bổ giảm điểm có thời hạn, đã xảy ra lỗi: %1';
								|ru = 'При выполнении распределения списания срочных баллов произошла ошибка: %1';
								|en = 'An error occurred when allocating the write-off of fixed-term bonus points: %1'; fa = 'An error occurred when allocating the write-off of fixed-term bonus points: %1';
								|it = 'Durante l''esecuzione della distribuzione dello storno dei punti urgenti si è verificato un errore: %1';
								|pl = 'Podczas wykonania przydzielenia rozchodu pilnych punktów wystąpił błąd: %1';
								|tr = 'Acil puanların silinmesi sırasında hata oluştu: %1'");
			MessageText = StrReplace(MessageText,"%1", ErrorText);
			
			WriteLogEvent(NStr("vi = 'Phân bổ điểm thưởng có thời hạn';
								|ru = 'Распределение срочных бонусных баллов';
								|en = 'Allocate fixed-term bonus points'; fa = 'تخصیص امتیازهای پاداش مدت‌دار';
								|it = 'Distribuzione punti bonus urgenti';
								|pl = 'Przydzielenie polnych punktów bonusowych';
								|tr = 'Acil bonus puanların dağıtımı'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , ,
				MessageText);
			Break;
		EndIf;
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, Round(NumberOfProcessedData/100));
	
	Return DistributionIsSuccessful;
	
EndFunction

// Distribute the write-off of urgent bonus points in the status for processing.
// 
// Parameters:
//  StartDateOfBonusPointsMechanism_2_5 - Date - Start date of the bonus points mechanism 2_5
//  PortionSize - Number - Number of records to be processed
//  ErrorText - String - the text of the error message
// 
// Returns:
//  Number - The number of processed documents to which the distribution was applied.
Function DistributeWriteOffOfUrgentBonusPointsInStatusForProcessing(StartDateOfBonusPointsMechanism_2_5,
	PortionSize = Undefined, ErrorText = "")
	
	QueryResult = RequestResultDeductionOfBonusPointsInStatusForProcessing(
		StartDateOfBonusPointsMechanism_2_5,
		PortionSize);
	NumberOfPackages_ = QueryResult.Count();
	
	ResultOfDebitingRequest = QueryResult[NumberOfPackages_ - 6];
	QueryResultBalance = QueryResult[NumberOfPackages_ - 5];
	RequestResultForAccrualReturns = QueryResult[NumberOfPackages_ - 4];
	ResultOfRequestForWriteOffReturns = QueryResult[NumberOfPackages_ - 3];
	ResultOfDistributedWriteOffRequest = QueryResult[NumberOfPackages_ - 2];
	QueryResultOpeningBalance = QueryResult[NumberOfPackages_ - 1];
	
	PartnerBalanceTable = New ValueTable;
	PartnerBalanceTable.Columns.Add("Recorder");
	PartnerBalanceTable.Columns.Add("Period");
	PartnerBalanceTable.Columns.Add("BalanceOfUrgentBonusPoints");
	PartnerBalanceTable.Columns.Add("ValidityStartDate");
	PartnerBalanceTable.Columns.Add("LoyaltyProgram");
	PartnerBalanceTable.Columns.Add("Partner");
	
	TableOfAccrualReturns = RequestResultForAccrualReturns.Unload();
	TableOfDebits = ResultOfDebitingRequest.Unload();
	RefundTable = ResultOfRequestForWriteOffReturns.Unload();
	TableOfDistributedWriteOff = ResultOfDistributedWriteOffRequest.Unload();
	TableOfInitialBalances = QueryResultOpeningBalance.Unload();
	
	SampleBalancesLoyaltyBonusProgram = QueryResultBalance.Select(
		QueryResultIteration.ByGroups,
		"LoyaltyProgram");
	
	ProcessedDocumentsCount = 0;
	While SampleBalancesLoyaltyBonusProgram.Next() Do
		
		SampleBalancesPartner = SampleBalancesLoyaltyBonusProgram.Select(
			QueryResultIteration.ByGroups,
			"Partner");
		
		While SampleBalancesPartner.Next() Do
			
			TheStructureOfTheSearch = New Structure("LoyaltyProgram, Partner");
			FillPropertyValues(TheStructureOfTheSearch, SampleBalancesPartner);
			
			// Get a table of balances of current urgent bonus points
			SamplingBalanceDetails = SampleBalancesPartner.Select();
			
			PartnerBalanceTable.Clear();
			While SamplingBalanceDetails.Next() Do
				RowTableOfBalancesByPartner = PartnerBalanceTable.Add();
				FillPropertyValues(RowTableOfBalancesByPartner, SamplingBalanceDetails);
			EndDo;
			
			// Get the amount of the buyer's debt
			TableOfInitialBalancesByPartner = TableOfInitialBalances.Copy(TheStructureOfTheSearch);
			AmountOfBuyerSDebt = TableOfInitialBalancesByPartner.Total("AccruedBalance");
			If TableOfInitialBalancesByPartner.Total("ToWriteOffBalance") <> 0 Then
				AmountOfBuyerSDebt = 0;
			EndIf;
			ThereIsDebtOfBuyer = ?(AmountOfBuyerSDebt = 0, False, True);
			
			// If the accrual is still valid, do not distribute the dogl and other expenses
			// and wait for the accrual to expire
			If ThereIsDebtOfBuyer
				And PartnerBalanceTable.Count() > 0 Then
				
				PartnerBalanceTable.Sort("Period");
				If PartnerBalanceTable[0].Period > BegOfDay(CurrentSessionDate()) Then
					Continue;
				EndIf;
			EndIf;
			
			// Get a table of returns of accruals for processing
			TableOfReturnsOfAccrualsByPartner = TableOfAccrualReturns.Copy(TheStructureOfTheSearch);
			TableOfReturnsOfAccrualsByPartner.Sort("Period");
			
			// Get a table of bonus points write-off for processing
			TableOfDebitsByPartner = TableOfDebits.Copy(TheStructureOfTheSearch);
			TableOfDebitsByPartner.Sort("DateBonusPointsWereDebited");
			
			// Get a table of bonus points returns for processing
			TableOfRefundsByPartner = RefundTable.Copy(TheStructureOfTheSearch);
			AmountOfReturnsByPartner = TableOfRefundsByPartner.Total("AmountOfBonusPointsRefund");
			
			BeginTransaction();
				
			Try
				
				DataChanged1 = False;
				
				ReduceAmountOfBonusPointsAccrualsByReturnAmount(
					PartnerBalanceTable,
					TableOfReturnsOfAccrualsByPartner);
				
				DistributeBuyerSDebtAccordingToBalanceOfAccrualBonusPoints(
					AmountOfBuyerSDebt,
					PartnerBalanceTable,
					DataChanged1);
				
				// Distribute the write-off of urgent bonus points
				For Each RowTableOfDebitsByPartner In TableOfDebitsByPartner Do
					
					// Get a table of write-off amounts that have been allocated for the accrual of urgent bonus points,
					// the validity of which has been completed
					TheStructureOfTheSearch = New Structure("LoyaltyProgram, Partner, DocumentForDebitingBonusPoints");
					FillPropertyValues(TheStructureOfTheSearch, RowTableOfDebitsByPartner);
					
					TableOfDistributedWriteOffByRecorders = TableOfDistributedWriteOff.Copy(TheStructureOfTheSearch);
					AmountOfPointsDistributedByRecorder = TableOfDistributedWriteOffByRecorders.Total("AmountOfBonusPointsDebited");
					
					AmountOfWriteOffToRecordersBalance
						= RowTableOfDebitsByPartner.AmountOfBonusPointsDebited
						- AmountOfPointsDistributedByRecorder;
						
					// Withdraw returned payment returns from distribution
					AmountOfReturnByRecordersOfWriteOff = Min(
						AmountOfWriteOffToRecordersBalance,
						AmountOfReturnsByPartner);
					AmountOfReturnsByPartner = AmountOfReturnsByPartner - AmountOfReturnByRecordersOfWriteOff;
					
					ToSetOffReturnAmountInAmountOfWriteOffOfBonusPoints(
						RowTableOfDebitsByPartner,
						TableOfRefundsByPartner,
						AmountOfReturnByRecordersOfWriteOff,
						AmountOfWriteOffToRecordersBalance,
						DataChanged1);
						
					RemoveRecordersOfBuyerSDebtFromPhoto(
						ThereIsDebtOfBuyer,
						AmountOfBuyerSDebt,
						RowTableOfDebitsByPartner,
						PartnerBalanceTable,
						DataChanged1);
					
					PartnerBalanceTable.Sort("Period");
					DistributeAmountOfWriteOffAccordingToValidityPeriodOfBonusPoints(
						RowTableOfDebitsByPartner,
						PartnerBalanceTable,
						DataChanged1);
					
					If DataChanged1 Then
						ProcessedDocumentsCount = ProcessedDocumentsCount + 1;
						DataChanged1 = False;
					EndIf;
				
				EndDo;
				
				// Remove Processed Documents From Registration
				RemoveProcessedDocumentsFromRegistration(
					TableOfReturnsOfAccrualsByPartner,
					PartnerBalanceTable,
					TableOfDebitsByPartner);
				
				CommitTransaction();
				
			Except
				
				If TransactionActive() Then
					RollbackTransaction();
				EndIf;
				ErrorInfo = ErrorInfo();
				ErrorText = ErrorInfo.Description;
				Break;
				
			EndTry;
			
		EndDo;
		
	EndDo;
	
	Return ProcessedDocumentsCount;
	
EndFunction

// Returns the result of the request containing the deducted bonus points in the status for processing.
// 
// Parameters:
//  SliceDate - Date - Start date of the bonus points mechanism 2_5
//  PortionSize - Number - The number of records to be processed. Default = 1000
// 
// Returns:
//  QueryResult - The result of the request containing the deducted bonus points for processing
//
Function RequestResultDeductionOfBonusPointsInStatusForProcessing(SliceDate, PortionSize = Undefined)
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT TOP 1000
	|	BonusPoints.Recorder.PointInTime AS LoggerIsMomentInTime,
	|	BEGINOFPERIOD(BonusPoints.Period, DAY) AS DateBonusPointsWereDebited,
	|	BonusPoints.Recorder AS DocumentForDebitingBonusPoints,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.Accrued) AS AmountOfBonusPointsDebited
	|INTO DeductionOfBonusPointsForProcessing
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.DateToProcess >= &StartDateOfBonusPointsMechanism
	|	AND BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND BonusPoints.RecordType = &RecordTypeExpense
	|	AND BonusPoints.Accrued > 0
	|
	|GROUP BY
	|	BonusPoints.Recorder.PointInTime,
	|	BEGINOFPERIOD(BonusPoints.Period, DAY),
	|	BonusPoints.Recorder,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner
	|
	|INDEX BY
	|	Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BonusPoints.DateBonusPointsWereDebited AS DateBonusPointsWereDebited,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner
	|INTO BonusPointsReturnPeriods
	|FROM
	|	DeductionOfBonusPointsForProcessing AS BonusPoints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(BonusPoints.Period, DAY) AS DateBonusPointsWereDebited,
	|	BonusPoints.Recorder AS DocumentForRefundOfBonusPoints,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(-BonusPoints.Accrued) AS AmountOfBonusPointsRefund
	|INTO ReturnsOfBonusPointsForProcessingNew
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.DateToProcess >= &StartDateOfBonusPointsMechanism
	|	AND BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND BonusPoints.RecordType = &RecordTypeExpense
	|	AND BonusPoints.Accrued < 0
	|	AND (BEGINOFPERIOD(BonusPoints.Period, DAY), LoyaltyProgram, Partner) IN (
	|		SELECT DISTINCT
	|			BonusPoints.DateBonusPointsWereDebited,
	|			BonusPoints.LoyaltyProgram,
	|			BonusPoints.Partner
	|		FROM BonusPointsReturnPeriods AS BonusPoints
	|	)
	|
	|GROUP BY
	|	BEGINOFPERIOD(BonusPoints.Period, DAY),
	|	BonusPoints.Recorder,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.DateBonusPointsWereDebited AS DateBonusPointsWereDebited,
	|	BonusPoints.DocumentForDebitingBonusPoints AS DocumentForDebitingBonusPoints,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.AmountOfBonusPointsDebited) AS AmountOfBonusPointsDebited
	|INTO PeriodsOfBonusPointsWriteOff
	|FROM
	|	DeductionOfBonusPointsForProcessing AS BonusPoints
	|
	|GROUP BY
	|	BonusPoints.DateBonusPointsWereDebited,
	|	BonusPoints.DocumentForDebitingBonusPoints,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.Period AS DateBonusPointsWereDebited,
	|	BonusPoints.Recorder AS DocumentForDebitingBonusPoints,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.ToWriteOff) AS AmountOfBonusPointsDebited
	|INTO WriteOffForCompletedAccruals
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.DateToProcess = DATETIME(1, 1, 1)
	|	AND BonusPoints.RecordType = &RecordTypeExpense
	|	AND BonusPoints.ToWriteOff <> 0
	|	AND (BonusPoints.Recorder, BonusPoints.LoyaltyProgram, BonusPoints.Partner) IN (
	|		SELECT
	|			BonusPoints.DocumentForDebitingBonusPoints AS DocumentForDebitingBonusPoints,
	|			BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|			BonusPoints.Partner AS Partner
	|		FROM
	|			PeriodsOfBonusPointsWriteOff AS BonusPoints
	|	)
	|
	|GROUP BY
	|	BonusPoints.Period,
	|	BonusPoints.Recorder,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	BonusPoints.Period AS Period
	|INTO SelectionStart
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND BonusPoints.DateToProcess >= &StartDateOfBonusPointsMechanism
	|
	|ORDER BY
	|	Period
	|
	|INDEX BY
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CASE
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.Accrued > 0
	|				AND BonusPoints.ToWriteOff = 0
	|			THEN ""Accrual""
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.ToWriteOff > 0
	|				AND BonusPoints.Accrued = 0
	|			THEN ""AccrualWriteOff""
	|		ELSE """"
	|	END AS OperationKind,
	|	BonusPoints.Period AS Period,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.Accrued) AS Accrued,
	|	SUM(BonusPoints.ToWriteOff) AS ToWriteOff,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.Recorder AS Recorder
	|INTO RegisteredRecordsOfAccrualsOfBonusPoints
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|	INNER JOIN SelectionStart AS SelectionStart
	|	ON BonusPoints.Period >= SelectionStart.Period
	|WHERE
	|	BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND ((BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.Accrued > 0
	|				AND BonusPoints.ToWriteOff = 0)
	|		OR (BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.ToWriteOff > 0
	|				AND BonusPoints.Accrued = 0)
	|	AND (LoyaltyProgram, Partner) IN (
	|		SELECT DISTINCT
	|			BonusPoints.LoyaltyProgram,
	|			BonusPoints.Partner
	|		FROM BonusPointsReturnPeriods AS BonusPoints))
	|				
	|GROUP BY
	|	CASE
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.Accrued > 0
	|				AND BonusPoints.ToWriteOff = 0
	|			THEN ""Accrual""
	|		WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				AND BonusPoints.ToWriteOff > 0
	|				AND BonusPoints.Accrued = 0
	|			THEN ""AccrualWriteOff""
	|		ELSE """"
	|	END,
	|	BonusPoints.Period,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.Period AS Period,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.Accrued AS Accrued,
	|	BonusPointsDeduction.ToWriteOff AS ToWriteOff,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPointsDeduction.Period AS DateForWriteOff,
	|	BonusPoints.Recorder AS Recorder
	|INTO RegisteredRecordsOfAccrualsOfBonusPointsAreReadyForProcessing
	|FROM
	|	RegisteredRecordsOfAccrualsOfBonusPoints AS BonusPoints
	|	INNER JOIN RegisteredRecordsOfAccrualsOfBonusPoints AS BonusPointsDeduction
	|	ON BonusPoints.Period = BonusPointsDeduction.ValidityStartDate
	|		AND BonusPoints.Recorder = BonusPointsDeduction.Recorder
	|		AND BonusPoints.LoyaltyProgram = BonusPointsDeduction.LoyaltyProgram
	|		AND BonusPoints.Partner = BonusPointsDeduction.Partner
	|		AND BonusPoints.OperationKind = ""Accrual""
	|		AND BonusPointsDeduction.OperationKind = ""AccrualWriteOff""
	|	
	|WHERE
	|	BonusPointsDeduction.Period <> DATETIME(1, 1, 1)
	|	AND BonusPoints.ValidityStartDate <> DATETIME(1, 1, 1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 	
	|	LoyaltyProgram AS LoyaltyProgram,
	|	Partner AS Partner,
	|	MIN(ValidityStartDate) AS ValidityStartDate
	|INTO FirstSlicesOfBalance
	|FROM
	|	RegisteredRecordsOfAccrualsOfBonusPointsAreReadyForProcessing AS BonusPoints
	|	
	|GROUP BY
	|	LoyaltyProgram,
	|	Partner
	|
	|INDEX BY
	|	Partner,
	|	ValidityStartDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	MIN(ValidityStartDate) AS MinimumBalancePeriod
	|FROM
	|	FirstSlicesOfBalance
	|
	|HAVING
	|	NOT MIN(ValidityStartDate) IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RegisteredRecordsOfAccrualsOfBonusPointsAreReadyForProcessing
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RegisteredRecordsOfAccrualsOfBonusPoints
	|;";
	Query.SetParameter("StartDateOfBonusPointsMechanism", SliceDate);
	Query.SetParameter("RecordTypeReceipt", AccumulationRecordType.Receipt);
	Query.SetParameter("RecordTypeExpense", AccumulationRecordType.Expense);
	
	If PortionSize <> Undefined Then
		Query.Text = StrReplace(Query.Text , "TOP 1000", "FIRST " + Format(PortionSize, "NG=;"));
	EndIf;
	
	RequestingPreliminaryData = Query.ExecuteBatch();
	NumberOfRequests_ = RequestingPreliminaryData.Count();
	
	RequiredToCalculateOpeningBalance = False;
	EarlyBalancePeriod = CurrentSessionDate();
	QuerySelection = RequestingPreliminaryData[NumberOfRequests_ - 3].Select();
	If QuerySelection.Next() Then
		If ValueIsFilled(QuerySelection.MinimumBalancePeriod) Then
			EarlyBalancePeriod = QuerySelection.MinimumBalancePeriod;
			RequiredToCalculateOpeningBalance = True;
		EndIf;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = "
	|SELECT
	|	BalancesAtBeginningOfPeriods.LoyaltyProgram AS LoyaltyProgram,
	|	BalancesAtBeginningOfPeriods.Partner AS Partner,
	|	MAX(BalancesAtBeginningOfPeriods.RemainderPeriod) AS RemainderPeriod,
	|	SUM(BalancesAtBeginningOfPeriods.AccruedBalance) AS AccruedBalance,
	|	SUM(BalancesAtBeginningOfPeriods.ToWriteOffBalance) AS ToWriteOffBalance
	|INTO BalancesAtBeginningsOfPeriods 
	|FROM 
	|	(SELECT
	|		BalanceOfPointsIsGeneral.LoyaltyProgram AS LoyaltyProgram,
	|		BalanceOfPointsIsGeneral.Partner AS Partner,
	|		UNDEFINED AS Period,
	|		UNDEFINED AS ValidityStartDate,
	|		BEGINOFPERIOD(&EarlyBalancePeriod, DAY) AS RemainderPeriod,
	|		BalanceOfPointsIsGeneral.AccruedBalance AS AccruedBalance,
	|		BalanceOfPointsIsGeneral.ToWriteOffBalance AS ToWriteOffBalance
	|	FROM AccumulationRegister.BonusPoints.Balance(&EarlyBalancePeriod, 
	|		(LoyaltyProgram, Partner) IN (
	|			SELECT
	|				FirstSlicesOfBalance.LoyaltyProgram,
	|				FirstSlicesOfBalance.Partner
	|			FROM
	|				FirstSlicesOfBalance)) AS BalanceOfPointsIsGeneral
	|		WHERE
	|			&RequiredToCalculateOpeningBalance
	|	
	|	UNION ALL
	|
	|	SELECT
	|		DeltasOfBalances.LoyaltyProgram AS LoyaltyProgram,
	|		DeltasOfBalances.Partner AS Partner,
	|		DeltasOfBalances.Period AS Period,
	|		BalancePeriods.ValidityStartDate AS ValidityStartDate,
	|		BalancePeriods.ValidityStartDate AS RemainderPeriod,
	|		CASE
	|			WHEN DeltasOfBalances.RecordType = &RecordTypeReceipt
	|				THEN 1
	|			ELSE -1
	|		END * DeltasOfBalances.Accrued AS AccruedBalance,
	|		CASE
	|			WHEN DeltasOfBalances.RecordType = &RecordTypeReceipt 
	|				THEN 1
	|			ELSE -1
	|		END * DeltasOfBalances.ToWriteOff AS ToWriteOffBalance
	|	FROM
	|		AccumulationRegister.BonusPoints AS DeltasOfBalances
	|		INNER JOIN FirstSlicesOfBalance AS BalancePeriods
	|		ON BalancePeriods.LoyaltyProgram = DeltasOfBalances.LoyaltyProgram
	|			AND BalancePeriods.Partner = DeltasOfBalances.Partner
	|			AND BalancePeriods.ValidityStartDate > DeltasOfBalances.Period
	|	WHERE
	|		&RequiredToCalculateOpeningBalance
	|		AND DeltasOfBalances.Period > &EarlyBalancePeriod) AS BalancesAtBeginningOfPeriods
	|
	|GROUP BY
	|	BalancesAtBeginningOfPeriods.LoyaltyProgram,
	|	BalancesAtBeginningOfPeriods.Partner
	|
	|HAVING 
	|	SUM(BalancesAtBeginningOfPeriods.AccruedBalance) < 0
	|
	|INDEX BY
	|	Partner,
	|	RemainderPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeductionOfBonusPointsForProcessing.DateBonusPointsWereDebited AS DateBonusPointsWereDebited,
	|	DeductionOfBonusPointsForProcessing.DocumentForDebitingBonusPoints AS DocumentForDebitingBonusPoints,
	|	DeductionOfBonusPointsForProcessing.DocumentForDebitingBonusPoints.Date AS DocumentForDebitingBonusPointsDate,
	|	DeductionOfBonusPointsForProcessing.LoyaltyProgram AS LoyaltyProgram,
	|	DeductionOfBonusPointsForProcessing.LoyaltyProgram.Description AS LoyaltyBonusProgramName,
	|	DeductionOfBonusPointsForProcessing.Partner AS Partner,
	|	DeductionOfBonusPointsForProcessing.Partner.Description AS PartnerName_,
	|	DeductionOfBonusPointsForProcessing.AmountOfBonusPointsDebited AS AmountOfBonusPointsDebited
	|FROM
	|	DeductionOfBonusPointsForProcessing AS DeductionOfBonusPointsForProcessing
	|
	|ORDER BY
	|	DeductionOfBonusPointsForProcessing.LoggerIsMomentInTime,
	|	DocumentForDebitingBonusPointsDate,
	|	PartnerName_,
	|	LoyaltyBonusProgramName
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.Recorder AS Recorder,
	|	BonusPoints.Period AS Period,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(CASE
	|			WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				THEN BonusPoints.ToWriteOff
	|			ELSE -BonusPoints.ToWriteOff
	|		END) AS BalanceOfUrgentBonusPoints,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.DateToProcess >= &StartDateOfBonusPointsMechanism
	|	AND BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND BonusPoints.ToWriteOff <> 0
	|	AND (BonusPoints.Partner, BonusPoints.LoyaltyProgram) IN
	|			(SELECT DISTINCT
	|				DeductionOfBonusPointsForProcessing.Partner,
	|				DeductionOfBonusPointsForProcessing.LoyaltyProgram
	|			FROM
	|				DeductionOfBonusPointsForProcessing AS DeductionOfBonusPointsForProcessing
	|			
	|			UNION ALL
	|			
	|			SELECT DISTINCT
	|				BalancesAtBeginningsOfPeriods.Partner,
	|				BalancesAtBeginningsOfPeriods.LoyaltyProgram
	|			FROM
	|				BalancesAtBeginningsOfPeriods AS BalancesAtBeginningsOfPeriods)
	|
	|GROUP BY
	|	BonusPoints.Recorder,
	|	BonusPoints.Period,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate
	|
	|HAVING
	|	SUM(CASE
	|			WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				THEN BonusPoints.ToWriteOff
	|			ELSE -BonusPoints.ToWriteOff
	|		END) > 0
	|
	|ORDER BY
	|	BonusPoints.Period
	|TOTALS BY
	|	LoyaltyProgram,
	|	Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.Recorder AS Recorder,
	|	BonusPoints.Period AS Period,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(-BonusPoints.ToWriteOff) AS AmountOfAccrualReturn,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.DateToProcess >= &StartDateOfBonusPointsMechanism
	|	AND BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND BonusPoints.ToWriteOff < 0
	|	AND (BonusPoints.Partner, BonusPoints.LoyaltyProgram) IN
	|			(SELECT DISTINCT
	|				DeductionOfBonusPointsForProcessing.Partner,
	|				DeductionOfBonusPointsForProcessing.LoyaltyProgram
	|			FROM
	|				DeductionOfBonusPointsForProcessing AS DeductionOfBonusPointsForProcessing
	|			
	|			UNION ALL
	|			
	|			SELECT DISTINCT
	|				BalancesAtBeginningsOfPeriods.Partner,
	|				BalancesAtBeginningsOfPeriods.LoyaltyProgram
	|			FROM
	|				BalancesAtBeginningsOfPeriods AS BalancesAtBeginningsOfPeriods)
	|
	|GROUP BY
	|	BonusPoints.Recorder,
	|	BonusPoints.Period,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate
	|
	|ORDER BY
	|	BonusPoints.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.DateBonusPointsWereDebited AS DateBonusPointsWereDebited,
	|	BonusPoints.DocumentForRefundOfBonusPoints AS DocumentForRefundOfBonusPoints,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.AmountOfBonusPointsRefund AS AmountOfBonusPointsRefund
	|FROM
	|	ReturnsOfBonusPointsForProcessingNew AS BonusPoints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.DateBonusPointsWereDebited AS DateBonusPointsWereDebited,
	|	BonusPoints.DocumentForDebitingBonusPoints AS DocumentForDebitingBonusPoints,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.AmountOfBonusPointsDebited AS AmountOfBonusPointsDebited
	|FROM
	|	WriteOffForCompletedAccruals AS BonusPoints
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalancesAtBeginningsOfPeriods.LoyaltyProgram AS LoyaltyProgram,
	|	BalancesAtBeginningsOfPeriods.Partner AS Partner,
	|	BalancesAtBeginningsOfPeriods.RemainderPeriod AS RemainderPeriod,
	|	-BalancesAtBeginningsOfPeriods.AccruedBalance AS AccruedBalance,
	|	BalancesAtBeginningsOfPeriods.ToWriteOffBalance AS ToWriteOffBalance
	|FROM
	|	BalancesAtBeginningsOfPeriods AS BalancesAtBeginningsOfPeriods
	|";
	Query.SetParameter("StartDateOfBonusPointsMechanism", SliceDate);
	Query.SetParameter("EarlyBalancePeriod", EarlyBalancePeriod);
	Query.SetParameter("RecordTypeReceipt", AccumulationRecordType.Receipt);
	Query.SetParameter("RequiredToCalculateOpeningBalance", RequiredToCalculateOpeningBalance);
	
	If PortionSize <> Undefined Then
		Query.Text = StrReplace(Query.Text , "TOP 1000", "FIRST " + Format(PortionSize, "NG=;"));
	EndIf;
	
	Return Query.ExecuteBatch();
	
EndFunction

Procedure ToSetOffReturnAmountInAmountOfWriteOffOfBonusPoints(RowOfWriteOffTable,
	RefundTable, ReturnAmount, DebitedAmount, DataChanged1)
	
	For Each RowTableOfReturns In RefundTable Do
		
		If ReturnAmount = 0 Then
			Continue;
		EndIf;
		
		AmountOfReturnByRecordersOfReturn = Min(
			ReturnAmount,
			RowTableOfReturns.AmountOfBonusPointsRefund);
			
		// Remove the payment return Recorder from processing if it is fully credited
		If AmountOfReturnByRecordersOfReturn = RowTableOfReturns.AmountOfBonusPointsRefund Then
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
			LockItem.SetValue("Recorder", RowTableOfReturns.DocumentForRefundOfBonusPoints);
			
			Block.Lock();
			
			SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
			SetOfPHEntriesBonusPoints.Filter.Recorder.Value = RowTableOfReturns.DocumentForRefundOfBonusPoints;
			SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
			SetOfPHEntriesBonusPoints.Read();
			
			For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
				
				If Not (RowTableOfReturns.DateBonusPointsWereDebited = StringRecordsetPHBonusPoints.Period
					And RowTableOfReturns.LoyaltyProgram = StringRecordsetPHBonusPoints.LoyaltyProgram
					And RowTableOfReturns.Partner = StringRecordsetPHBonusPoints.Partner) Then
					Continue;
				EndIf; 
				
				StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
				
			EndDo;
			
			SetOfPHEntriesBonusPoints.Write();
			
			RowTableOfReturns.AmountOfBonusPointsRefund
				= RowTableOfReturns.AmountOfBonusPointsRefund - AmountOfReturnByRecordersOfReturn;
			
			DataChanged1 = True;
			
		Else
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
			LockItem.SetValue("Recorder", RowTableOfReturns.DocumentForRefundOfBonusPoints);
			
			Block.Lock();
			
			SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
			SetOfPHEntriesBonusPoints.Filter.Recorder.Value = RowTableOfReturns.DocumentForRefundOfBonusPoints;
			SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
			SetOfPHEntriesBonusPoints.Read();
			
			For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
				
				If Not (RowTableOfReturns.DateBonusPointsWereDebited = StringRecordsetPHBonusPoints.Period
					And RowTableOfReturns.LoyaltyProgram = StringRecordsetPHBonusPoints.LoyaltyProgram
					And RowTableOfReturns.Partner = StringRecordsetPHBonusPoints.Partner) Then
					Continue;
				EndIf; 
				
				If AmountOfReturnByRecordersOfReturn < RowTableOfReturns.AmountOfBonusPointsRefund Then
					StringRecordsetPHBonusPoints.Accrued = - AmountOfReturnByRecordersOfReturn;
				EndIf;
				
				StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
				
			EndDo;
			
			StringRecordsetPHBonusPoints = SetOfPHEntriesBonusPoints.Add();
			StringRecordsetPHBonusPoints.Period = RowTableOfReturns.DateBonusPointsWereDebited;
			StringRecordsetPHBonusPoints.RecordType = AccumulationRecordType.Expense;
			StringRecordsetPHBonusPoints.LoyaltyProgram
				= RowTableOfReturns.LoyaltyProgram;
			StringRecordsetPHBonusPoints.Partner
				= RowTableOfReturns.Partner;
			StringRecordsetPHBonusPoints.Accrued
				= -(RowTableOfReturns.AmountOfBonusPointsRefund - AmountOfReturnByRecordersOfReturn);
			StringRecordsetPHBonusPoints.DateToProcess = CurrentSessionDate();
			
			SetOfPHEntriesBonusPoints.Write();
			
			RowTableOfReturns.AmountOfBonusPointsRefund
				= RowTableOfReturns.AmountOfBonusPointsRefund - AmountOfReturnByRecordersOfReturn;
			
			DataChanged1 = True;
			
		EndIf;
		
		// To remove the write-off (payment) Recorder from processing if it is fully credited
		ArrayOfRowsOfDistributedWriteOffToDelete = New Array;
		If AmountOfReturnByRecordersOfReturn = DebitedAmount Then
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
			LockItem.SetValue("Recorder", RowOfWriteOffTable.DocumentForDebitingBonusPoints);
			
			Block.Lock();
			
			SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
			SetOfPHEntriesBonusPoints.Filter.Recorder.Value = RowOfWriteOffTable.DocumentForDebitingBonusPoints;
			SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
			SetOfPHEntriesBonusPoints.Read();
			
			For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
				
				If Not (RowOfWriteOffTable.LoyaltyProgram = StringRecordsetPHBonusPoints.LoyaltyProgram
					And RowOfWriteOffTable.Partner = StringRecordsetPHBonusPoints.Partner
					And StringRecordsetPHBonusPoints.DateToProcess <> Date(1, 1, 1)) Then
					Continue;
				EndIf;
				
				If StringRecordsetPHBonusPoints.Accrued > 0
					And StringRecordsetPHBonusPoints.DateToProcess <> Date(1, 1, 1) Then
					
					StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
				EndIf;
				
				If StringRecordsetPHBonusPoints.ToWriteOff > 0
					And StringRecordsetPHBonusPoints.DateToProcess <> Date(1, 1, 1) Then
					
					ArrayOfRowsOfDistributedWriteOffToDelete.Add(StringRecordsetPHBonusPoints);
					
				EndIf;
				
			EndDo;
			
			For Each StringArrayOfStringsToDelete In ArrayOfRowsOfDistributedWriteOffToDelete Do
				SetOfPHEntriesBonusPoints.Delete(StringArrayOfStringsToDelete);
			EndDo;
			
			SetOfPHEntriesBonusPoints.Write();
			
			RowOfWriteOffTable.AmountOfBonusPointsDebited
				= DebitedAmount - AmountOfReturnByRecordersOfReturn;
			
			DataChanged1 = True;
			
		Else
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
			LockItem.SetValue("Recorder", RowOfWriteOffTable.DocumentForDebitingBonusPoints);
			
			Block.Lock();
			
			SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
			SetOfPHEntriesBonusPoints.Filter.Recorder.Value = RowOfWriteOffTable.DocumentForDebitingBonusPoints;
			SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
			SetOfPHEntriesBonusPoints.Read();
			
			AmountOfBalanceAccruedForDistribution = DebitedAmount - AmountOfReturnByRecordersOfReturn;
			For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
				
				If Not (RowOfWriteOffTable.LoyaltyProgram = StringRecordsetPHBonusPoints.LoyaltyProgram
					And RowOfWriteOffTable.Partner = StringRecordsetPHBonusPoints.Partner
					And StringRecordsetPHBonusPoints.DateToProcess <> Date(1, 1, 1)) Then
					Continue;
				EndIf; 
				
				// We are withdrawing from the distribution the amount of payment that was previously distributed and returned in the current distribution period
				If StringRecordsetPHBonusPoints.Accrued > 0
					And StringRecordsetPHBonusPoints.DateToProcess <> Date(1, 1, 1) Then
					
					If AmountOfBalanceAccruedForDistribution < StringRecordsetPHBonusPoints.Accrued Then
						StringRecordsetPHBonusPoints.Accrued
							= StringRecordsetPHBonusPoints.Accrued
							- (DebitedAmount - AmountOfReturnByRecordersOfReturn);
						AmountOfBalanceAccruedForDistribution = 0;
					Else
						AmountOfBalanceAccruedForDistribution
							= AmountOfBalanceAccruedForDistribution - StringRecordsetPHBonusPoints.Accrued;
					EndIf;
					
					StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
				EndIf;
				
				If StringRecordsetPHBonusPoints.ToWriteOff > 0
					And StringRecordsetPHBonusPoints.DateToProcess <> Date(1, 1, 1) Then
					
					ArrayOfRowsOfDistributedWriteOffToDelete.Add(StringRecordsetPHBonusPoints);
					
				EndIf;
				
			EndDo;
			
			For Each StringArrayOfStringsToDelete In ArrayOfRowsOfDistributedWriteOffToDelete Do
				SetOfPHEntriesBonusPoints.Delete(StringArrayOfStringsToDelete);
			EndDo;
			
			StringRecordsetPHBonusPoints = SetOfPHEntriesBonusPoints.Add();
			StringRecordsetPHBonusPoints.Period = RowOfWriteOffTable.DateBonusPointsWereDebited;
			StringRecordsetPHBonusPoints.RecordType = AccumulationRecordType.Expense;
			StringRecordsetPHBonusPoints.LoyaltyProgram
				= RowTableOfReturns.LoyaltyProgram;
			StringRecordsetPHBonusPoints.Partner
				= RowTableOfReturns.Partner;
			StringRecordsetPHBonusPoints.Accrued
				= DebitedAmount
				- AmountOfReturnByRecordersOfReturn;
			StringRecordsetPHBonusPoints.DateToProcess = CurrentSessionDate();
			
			SetOfPHEntriesBonusPoints.Write();
			
			RowOfWriteOffTable.AmountOfBonusPointsDebited
				= DebitedAmount - AmountOfReturnByRecordersOfReturn;
			
		EndIf;
		
		DataChanged1 = True;
		
	EndDo;
	
EndProcedure

// Distribute the amount of deduction according to the validity period of bonus points (indefinite or urgent bonus points).
// 
// Parameters:
//  RowTableOfDebitsByPartner - ValueTableRow - Data on the deduction of bonus points
//  PartnerBalanceTable - ValueTable - Table of current term bonus points balances
//  DataChanged1 - Boolean - Flag for changing data in movements to correctly count the number of processed
//  documents.
// 
Procedure DistributeAmountOfWriteOffAccordingToValidityPeriodOfBonusPoints(
	RowTableOfDebitsByPartner,
	PartnerBalanceTable,
	DataChanged1)
	
	// Method variables
	DocumentWriteOffs = RowTableOfDebitsByPartner.DocumentForDebitingBonusPoints;
	DateOfDeduction     = RowTableOfDebitsByPartner.DateBonusPointsWereDebited;
	
	Partner  = RowTableOfDebitsByPartner.Partner;
	LoyaltyProgram  = RowTableOfDebitsByPartner.LoyaltyProgram;
	
	AmountOfBonusPointsDeductedTakingIntoAccountDistribution = RowTableOfDebitsByPartner.AmountOfBonusPointsDebited;
	
	// Setting a lock
	Block = New DataLock;
	
	LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
	LockItem.SetValue("Recorder", DocumentWriteOffs);
	
	Block.Lock();
	
	// Distribution of bonus points deduction according to the balances of current urgent bonus points
	SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
	SetOfPHEntriesBonusPoints.Filter.Recorder.Value = DocumentWriteOffs;
	SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
	SetOfPHEntriesBonusPoints.Read();
	
	For Each RowTableOfBalancesByPartner In PartnerBalanceTable Do
		
		If AmountOfBonusPointsDeductedTakingIntoAccountDistribution = 0 Then
			Break;
		EndIf;
		
		If DateOfDeduction < RowTableOfBalancesByPartner.ValidityStartDate
			Or DateOfDeduction > RowTableOfBalancesByPartner.Period
			Or RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints = 0 Then
			Continue;
		EndIf;
		
		BalanceOfUrgentBonusPoints = RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints;
		AmountOfValueCorrectionToBeDebited = Min(BalanceOfUrgentBonusPoints, AmountOfBonusPointsDeductedTakingIntoAccountDistribution);
		BalanceOfUrgentBonusPoints = BalanceOfUrgentBonusPoints - AmountOfValueCorrectionToBeDebited;
		
		AmountOfBonusPointsDeductedTakingIntoAccountDistribution = AmountOfBonusPointsDeductedTakingIntoAccountDistribution - AmountOfValueCorrectionToBeDebited;
		
		StringRecordsetPHBonusPoints = SetOfPHEntriesBonusPoints.Add();
		FillPropertyValues(
			StringRecordsetPHBonusPoints,
			RowTableOfBalancesByPartner);
		
		StringRecordsetPHBonusPoints.Recorder = DocumentWriteOffs;
		StringRecordsetPHBonusPoints.RecordType = AccumulationRecordType.Expense;
		StringRecordsetPHBonusPoints.ToWriteOff = AmountOfValueCorrectionToBeDebited;
		StringRecordsetPHBonusPoints.DateToProcess = CurrentSessionDate();
		
		RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints = BalanceOfUrgentBonusPoints;
		
		DataChanged1 = True;
		
	EndDo;
	
	For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
		If StringRecordsetPHBonusPoints.DateToProcess <> Date(1, 1, 1)
			And StringRecordsetPHBonusPoints.LoyaltyProgram = LoyaltyProgram
			And StringRecordsetPHBonusPoints.Partner = Partner
			And StringRecordsetPHBonusPoints.Accrued > 0 Then
			StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
		EndIf;
	EndDo;
	
	If DataChanged1 Then
		SetOfPHEntriesBonusPoints.Write();
	EndIf;
	
EndProcedure

Procedure ReduceAmountOfBonusPointsAccrualsByReturnAmount(PartnerBalanceTable, TableOfReturnsOfAccrualsByPartner)
	
	ReturnAmountAccruedByPartner = TableOfReturnsOfAccrualsByPartner.Total("AmountOfAccrualReturn");
	
	If TableOfReturnsOfAccrualsByPartner.Count() > 0 Then
		
		PartnerBalanceTable.Sort("Period");
		For Each RowTableOfBalancesByPartner In PartnerBalanceTable Do
			
			For Each RowTableOfAccrualReturnsByPartner In TableOfReturnsOfAccrualsByPartner Do
				
				If Not (RowTableOfAccrualReturnsByPartner.Period = RowTableOfBalancesByPartner.Period
					And RowTableOfAccrualReturnsByPartner.ValidityStartDate = RowTableOfBalancesByPartner.ValidityStartDate) Then
					Continue;
				EndIf;
				
				AmountOfReturnAccrualForProcessing = Min(
					RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints,
					RowTableOfAccrualReturnsByPartner.AmountOfAccrualReturn);
				
				RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints
					= RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints
					- AmountOfReturnAccrualForProcessing;
					
				RowTableOfAccrualReturnsByPartner.AmountOfAccrualReturn
					= RowTableOfAccrualReturnsByPartner.AmountOfAccrualReturn
					- AmountOfReturnAccrualForProcessing;
				
				ReturnAmountAccruedByPartner = ReturnAmountAccruedByPartner - AmountOfReturnAccrualForProcessing;
				
				If RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
			If ReturnAmountAccruedByPartner = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure DistributeBuyerSDebtAccordingToBalanceOfAccrualBonusPoints(AmountOfBuyerSDebt,
	PartnerBalanceTable, DataChanged1)
	
	ProcessedDocumentsCount = 0;
	
	If AmountOfBuyerSDebt > 0 Then
		
		PartnerBalanceTable.Sort("Period");
		For Each RowTableOfBalancesByPartner In PartnerBalanceTable Do
			
			If AmountOfBuyerSDebt = 0 Then
				Break;
			EndIf;
			
			If RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints = 0 Then
				Continue;
			EndIf;
			
			// Now you need to understand what amount is being debited from
			AmountOfDebtOffsetByAccrual = Min(
				AmountOfBuyerSDebt,
				RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints);
				
			// Put the offset amount under the accrual Recorder
			Block = New DataLock;

			LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
			LockItem.SetValue("Recorder", RowTableOfBalancesByPartner.Recorder);
			
			Block.Lock();
			
			SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
			SetOfPHEntriesBonusPoints.Filter.Recorder.Value = RowTableOfBalancesByPartner.Recorder;
			SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
			SetOfPHEntriesBonusPoints.Read();
			
			StringRecordsetPHBonusPoints = SetOfPHEntriesBonusPoints.Add();
			FillPropertyValues(StringRecordsetPHBonusPoints, RowTableOfBalancesByPartner);
			
			StringRecordsetPHBonusPoints.RecordType = AccumulationRecordType.Expense;
			StringRecordsetPHBonusPoints.Period = RowTableOfBalancesByPartner.Period;
			StringRecordsetPHBonusPoints.ToWriteOff = AmountOfDebtOffsetByAccrual;
			StringRecordsetPHBonusPoints.ValidityStartDate = RowTableOfBalancesByPartner.ValidityStartDate;
			StringRecordsetPHBonusPoints.DateToProcess = CurrentSessionDate();
			
			SetOfPHEntriesBonusPoints.Write();
			
			RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints
				= RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints
				- AmountOfDebtOffsetByAccrual;
			AmountOfBuyerSDebt = AmountOfBuyerSDebt - AmountOfDebtOffsetByAccrual;
			
			DataChanged1 = True;
			
		EndDo;
		
		If DataChanged1 Then
			ProcessedDocumentsCount = ProcessedDocumentsCount + 1;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure RemoveRecordersOfBuyerSDebtFromPhoto(ThereIsDebtOfBuyer, AmountOfBuyerSDebt,
	RowTableOfDebitsByPartner, PartnerBalanceTable, DataChanged1)
	
	If ThereIsDebtOfBuyer Then
		
		RemoveWriteOffRecorderFromProcessing = False;
		
		PartnerBalanceTable.Sort("Period");
		For Each RowTableOfBalancesByPartner In PartnerBalanceTable Do
			
			If RowTableOfBalancesByPartner.ValidityStartDate <= RowTableOfDebitsByPartner.DateBonusPointsWereDebited Then
				Break;
			EndIf;
			
			RemoveWriteOffRecorderFromProcessing = True;
			Break;
			
		EndDo;
		
		If RemoveWriteOffRecorderFromProcessing Then
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
			LockItem.SetValue("Recorder", RowTableOfDebitsByPartner.DocumentForDebitingBonusPoints);
			
			Block.Lock();
			
			SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
			SetOfPHEntriesBonusPoints.Filter.Recorder.Value = RowTableOfDebitsByPartner.DocumentForDebitingBonusPoints;
			SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
			SetOfPHEntriesBonusPoints.Read();
			
			For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
				
				If Not (RowTableOfDebitsByPartner.DateBonusPointsWereDebited = StringRecordsetPHBonusPoints.Period
					And RowTableOfDebitsByPartner.LoyaltyProgram = StringRecordsetPHBonusPoints.LoyaltyProgram
					And RowTableOfDebitsByPartner.Partner = StringRecordsetPHBonusPoints.Partner
					And StringRecordsetPHBonusPoints.DateToProcess <> Date(1, 1, 1)) Then
					Continue;
				EndIf; 
				
				StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
				
			EndDo;
			
			SetOfPHEntriesBonusPoints.Write();
			
			DataChanged1 = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure RemoveProcessedDocumentsFromRegistration(TableOfReturnsOfAccrualsByPartner,
	PartnerBalanceTable, TableOfDebitsByPartner)
	
	// Withdraw accrual returns that have expired
	For Each AccrualReturnData In TableOfReturnsOfAccrualsByPartner Do
		
		Block = New DataLock;

		LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
		LockItem.SetValue("Recorder", AccrualReturnData.Recorder);
		
		Block.Lock();
		
		SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
		SetOfPHEntriesBonusPoints.Filter.Recorder.Value = AccrualReturnData.Recorder;
		SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
		SetOfPHEntriesBonusPoints.Read();
		
		For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
			
			If Not (AccrualReturnData.Period <= BegOfDay(CurrentSessionDate())
				And AccrualReturnData.LoyaltyProgram = StringRecordsetPHBonusPoints.LoyaltyProgram
				And AccrualReturnData.Partner = StringRecordsetPHBonusPoints.Partner
				And StringRecordsetPHBonusPoints.DateToProcess <> Date(1, 1, 1)) Then
				Continue;
			EndIf; 
			
			StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
			
		EndDo;
		
		SetOfPHEntriesBonusPoints.Write();
		
	EndDo;
	
	// Withdraw accruals that have expired
	For Each RowTableOfBalancesByPartner In PartnerBalanceTable Do
		
		Block = New DataLock;

		LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
		LockItem.SetValue("Recorder", RowTableOfBalancesByPartner.Recorder);
		
		Block.Lock();
		
		SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
		SetOfPHEntriesBonusPoints.Filter.Recorder.Value = RowTableOfBalancesByPartner.Recorder;
		SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
		SetOfPHEntriesBonusPoints.Read();
		
		For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
			
			If Not (RowTableOfBalancesByPartner.Period <= BegOfDay(CurrentSessionDate())
				And RowTableOfBalancesByPartner.LoyaltyProgram = StringRecordsetPHBonusPoints.LoyaltyProgram
				And RowTableOfBalancesByPartner.Partner = StringRecordsetPHBonusPoints.Partner
				And StringRecordsetPHBonusPoints.DateToProcess <> Date(1, 1, 1)) Then
				Continue;
			EndIf; 
			
			StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
			
		EndDo;
		
		If RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints > 0
			And RowTableOfBalancesByPartner.Period <= BegOfDay(CurrentSessionDate()) Then
			
			StringRecordsetPHBonusPoints = SetOfPHEntriesBonusPoints.Add();
			FillPropertyValues(
				StringRecordsetPHBonusPoints,
				RowTableOfBalancesByPartner);
			
			StringRecordsetPHBonusPoints.RecordType = AccumulationRecordType.Receipt;
			StringRecordsetPHBonusPoints.Accrued = -RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints;
			StringRecordsetPHBonusPoints.ToWriteOff = -RowTableOfBalancesByPartner.BalanceOfUrgentBonusPoints;
			StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
			
		EndIf;
		
		SetOfPHEntriesBonusPoints.Write();
		
	EndDo;
	
	// Withdraw payments (write-off of accrual payments whose validity period has been completed)
	For Each RowTableOfDebitsByPartner In TableOfDebitsByPartner Do
		
		Block = New DataLock;

		LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
		LockItem.SetValue("Recorder", RowTableOfDebitsByPartner.DocumentForDebitingBonusPoints);
		
		Block.Lock();
		
		SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
		SetOfPHEntriesBonusPoints.Filter.Recorder.Value = RowTableOfDebitsByPartner.DocumentForDebitingBonusPoints;
		SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
		SetOfPHEntriesBonusPoints.Read();
		
		For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
			
			If Not (StringRecordsetPHBonusPoints.Period <= BegOfDay(CurrentSessionDate())
				And RowTableOfDebitsByPartner.LoyaltyProgram = StringRecordsetPHBonusPoints.LoyaltyProgram
				And RowTableOfDebitsByPartner.Partner = StringRecordsetPHBonusPoints.Partner
				And StringRecordsetPHBonusPoints.ToWriteOff <> 0
				And StringRecordsetPHBonusPoints.DateToProcess <> Date(1, 1, 1)) Then
				Continue;
			EndIf; 
			
			StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
			
		EndDo;
		
		SetOfPHEntriesBonusPoints.Write();
		
	EndDo;
	
	
EndProcedure

#EndRegion

#Region WriteOffOfBalancesOfExpiredUrgentBonusPoints

Procedure ProcessTerminatedActionsOfAccrualOfUrgentBonusPoints(StartDateOfBonusPointsMechanism_2_5)
	
	NumberOfProcessedData = 0;
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"ScheduledJob.AllocateFixedTermBonusPoints.WriteOffBalanceOfUrgentBonusPointsThatHaveExpired");
	
	RepeatDebiting = True;
	While RepeatDebiting Do
		ErrorText = "";
		
		ProcessedDocumentsCount = WriteOffBalanceOfUrgentBonusPointsThatHaveExpired(
			StartDateOfBonusPointsMechanism_2_5,
			Undefined,
			ErrorText);
			
		NumberOfProcessedData = NumberOfProcessedData + ProcessedDocumentsCount;
		RepeatDebiting = Not (ProcessedDocumentsCount = 0);
		If ValueIsFilled(ErrorText) Then
			
			MessageText = NStr("vi = 'Khi thực hiện giảm số dư điểm có thời hạn, đã xảy ra lỗi: %1';
								|ru = 'При выполнении списания остатков срочных баллов произошла ошибка: %1';
								|en = 'An error occurred when writing off the balance of fixed-term bonus points: %1'; fa = 'An error occurred when writing off the balance of fixed-term bonus points: %1';
								|it = 'Durante l''esecuzione dello storno dei saldi dei punti urgenti si è verificato un errore: %1';
								|pl = 'Podczas wykonania rozchodu reszty pilnych punktów wystąpił błąd: %1';
								|tr = 'Acil puan bakiyeleri kayıttan düşürülürken hata oluştu: %1'");
			MessageText = StrReplace(MessageText,"%1", ErrorText);
			
			WriteLogEvent(NStr("vi = 'Phân bổ điểm thưởng có kỳ hạn';
								|ru = 'Распределение срочных бонусных баллов';
								|en = 'Allocate fixed-term bonus points'; fa = 'تخصیص امتیازهای پاداش مدت‌دار';
								|it = 'Distribuzione punti bonus urgenti';
								|pl = 'Przydzielenie polnych punktów bonusowych';
								|tr = 'Acil bonus puanların dağıtımı'", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , ,
				MessageText);
			Break;
		EndIf;
	EndDo;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfProcessedData);
	
EndProcedure

// Writes off the balances of expired urgent bonus points.
// 
// Parameters:
//  StartDateOfBonusPointsMechanism_2_5 - Date - Start date of the bonus points mechanism 2_5
//  PortionSize - Number - Number of records to be processed
//  ErrorText - String - the text of the error message
//  
// Returns:
//  Number - The number of processed documents for which balances were written off.
//
Function WriteOffBalanceOfUrgentBonusPointsThatHaveExpired(StartDateOfBonusPointsMechanism_2_5,
	PortionSize = Undefined, ErrorText = "")
	
	QueryResult = RequestResultBalancesOfOverdueUrgentBonusPoints(
		StartDateOfBonusPointsMechanism_2_5,
		PortionSize);
	
	QueryResultBalance = QueryResult[1];
	ResultOfDocumentBalanceRequest = QueryResult[2];
	ResultOfRequestDocumentsToBeRemovedFromProcessing = QueryResult[3];
	
	TableOfBalancesToBeDebited = New ValueTable;
	TableOfBalancesToBeDebited.Columns.Add("LoyaltyProgram");
	TableOfBalancesToBeDebited.Columns.Add("Partner");
	TableOfBalancesToBeDebited.Columns.Add("StartDateOfActionOfUrgentBonusPoints");
	TableOfBalancesToBeDebited.Columns.Add("ExpirationDateOfUrgentBonusPoints");
	TableOfBalancesToBeDebited.Columns.Add("BalanceOfUrgentBonusPoints");
	
	TableOfDocumentBalances = New ValueTable;
	TableOfDocumentBalances.Columns.Add("LoyaltyProgram");
	TableOfDocumentBalances.Columns.Add("Partner");
	TableOfDocumentBalances.Columns.Add("Recorder");
	TableOfDocumentBalances.Columns.Add("DateToProcess");
	TableOfDocumentBalances.Columns.Add("ValidityStartDate");
	TableOfDocumentBalances.Columns.Add("Period");
	TableOfDocumentBalances.Columns.Add("ToWriteOff");
	
	TableOfDocumentsToBeRemovedFromProcessing = New ValueTable;
	TableOfDocumentsToBeRemovedFromProcessing.Columns.Add("LoyaltyProgram");
	TableOfDocumentsToBeRemovedFromProcessing.Columns.Add("Partner");
	TableOfDocumentsToBeRemovedFromProcessing.Columns.Add("Recorder");
	TableOfDocumentsToBeRemovedFromProcessing.Columns.Add("ValidityStartDate");
	TableOfDocumentsToBeRemovedFromProcessing.Columns.Add("Period");
	TableOfDocumentsToBeRemovedFromProcessing.Columns.Add("ToWriteOff");
	TableOfDocumentsToBeRemovedFromProcessing.Columns.Add("DateToProcess");
	
	SampleBalancesLoyaltyBonusProgram = QueryResultBalance.Select(QueryResultIteration.ByGroups, "LoyaltyProgram");
	SampleBalancesAccordingToDocumentsLoyaltyBonusProgram = ResultOfDocumentBalanceRequest.Select(QueryResultIteration.ByGroups, "LoyaltyProgram");
	SelectionOfDocumentsToBeWithdrawnFromProcessingLoyaltyBonusProgram = ResultOfRequestDocumentsToBeRemovedFromProcessing.Select(QueryResultIteration.ByGroups, "LoyaltyProgram");
	
	ProcessedDocumentsCount = 0;	
	While SampleBalancesLoyaltyBonusProgram.Next() Do
		
		SampleBalancesPartner = SampleBalancesLoyaltyBonusProgram.Select(QueryResultIteration.ByGroups, "Partner");
		
		While SampleBalancesPartner.Next() Do
			
			// Get a table of overdue urgent bonus points balances
			SamplingBalanceDetails = SampleBalancesPartner.Select();
			
			TableOfBalancesToBeDebited.Clear();
			While SamplingBalanceDetails.Next() Do
				RowTableOfBalancesToBeDebited = TableOfBalancesToBeDebited.Add();
				FillPropertyValues(RowTableOfBalancesToBeDebited, SamplingBalanceDetails);
			EndDo;
			
			// Get a table of accruals of urgent bonus points for writing off overdue urgent bonus points
			
			SearchStructureLoyaltyBonusProgram = New Structure;
			SearchStructureLoyaltyBonusProgram.Insert(
				"LoyaltyProgram",
				SampleBalancesLoyaltyBonusProgram.LoyaltyProgram);
				
			SampleBalancesAccordingToDocumentsLoyaltyBonusProgram.Reset();
			If SampleBalancesAccordingToDocumentsLoyaltyBonusProgram.FindNext(SearchStructureLoyaltyBonusProgram) Then
				
				SelectionOfBalancesForPartnerDocuments = SampleBalancesAccordingToDocumentsLoyaltyBonusProgram.Select(QueryResultIteration.ByGroups, "Partner");
				
				PartnerSearchStructure = New Structure;
				PartnerSearchStructure.Insert(
					"Partner",
					SampleBalancesPartner.Partner);
				
				If SelectionOfBalancesForPartnerDocuments.FindNext(PartnerSearchStructure) Then
					
					SamplingSamplingDocumentBalancesDetails = SelectionOfBalancesForPartnerDocuments.Select();
					
					TableOfDocumentBalances.Clear();
					While SamplingSamplingDocumentBalancesDetails.Next() Do
						RowTableOfBalancesForDocuments = TableOfDocumentBalances.Add();
						FillPropertyValues(RowTableOfBalancesForDocuments, SamplingSamplingDocumentBalancesDetails);
					EndDo;
					
				EndIf;
				
			EndIf;
			
			// Get a table of documents for withdrawal from further processing of the distribution of urgent bonus points
			
			SearchStructureLoyaltyBonusProgram = New Structure;
			SearchStructureLoyaltyBonusProgram.Insert(
				"LoyaltyProgram",
				SampleBalancesLoyaltyBonusProgram.LoyaltyProgram);
				
			SelectionOfDocumentsToBeWithdrawnFromProcessingLoyaltyBonusProgram.Reset();
			If SelectionOfDocumentsToBeWithdrawnFromProcessingLoyaltyBonusProgram.FindNext(SearchStructureLoyaltyBonusProgram) Then
				
				SelectionOfDocumentsToBeRemovedFromProcessingPartner = SelectionOfDocumentsToBeWithdrawnFromProcessingLoyaltyBonusProgram.Select(QueryResultIteration.ByGroups, "Partner");
				
				PartnerSearchStructure = New Structure;
				PartnerSearchStructure.Insert(
					"Partner",
					SampleBalancesPartner.Partner);
				
				If SelectionOfDocumentsToBeRemovedFromProcessingPartner.FindNext(PartnerSearchStructure) Then
					
					SelectionOfDocumentsToBeRemovedFromProcessingOfPart = SelectionOfDocumentsToBeRemovedFromProcessingPartner.Select();
					
					TableOfDocumentsToBeRemovedFromProcessing.Clear();
					While SelectionOfDocumentsToBeRemovedFromProcessingOfPart.Next() Do
						RowTableOfDocumentsToBeRemovedFromProcessing = TableOfDocumentsToBeRemovedFromProcessing.Add();
						FillPropertyValues(RowTableOfDocumentsToBeRemovedFromProcessing, SelectionOfDocumentsToBeRemovedFromProcessingOfPart);
					EndDo;
					
				EndIf;
				
			EndIf;
			
			For Each RowTableOfBalancesToBeDebited In TableOfBalancesToBeDebited Do
				
				BeginTransaction();
				
				Try
					
					DataChanged1 = False;
					
					// Write off overdue urgent bonus points from the register balances
					ZeroRowsOfBalancesToDelete = WriteOffBalanceOfOverdueUrgentBonusPoints(
						RowTableOfBalancesToBeDebited,
						TableOfDocumentBalances,
						DataChanged1);
					
					For Each RowToDelete In ZeroRowsOfBalancesToDelete Do
						TableOfDocumentBalances.Delete(RowToDelete);
					EndDo;
					
					// Remove documents from further processing of the distribution of urgent bonus points
					ZeroRowsOfBalancesToDelete = RemoveDocumentsFromStatusForProcessing(
						RowTableOfBalancesToBeDebited,
						TableOfDocumentsToBeRemovedFromProcessing,
						DataChanged1);
					
					For Each RowToDelete In ZeroRowsOfBalancesToDelete Do
						TableOfDocumentsToBeRemovedFromProcessing.Delete(RowToDelete);
					EndDo;
					
					If DataChanged1 Then
						ProcessedDocumentsCount = ProcessedDocumentsCount + 1;
					EndIf;
					
					CommitTransaction();
					
				Except
					
					If TransactionActive() Then
						RollbackTransaction();
					EndIf;
					ErrorInfo = ErrorInfo();
					ErrorText = ErrorInfo.Description;
					Break;
					
				EndTry;
				
			EndDo;
			
		EndDo;
			
	EndDo;
	
	Return ProcessedDocumentsCount;
	
EndFunction

// Returns the result of the request with the remaining overdue urgent bonus points.
// 
// Parameters:
//  StartDateOfBonusPointsMechanism_2_5 - Date - Start date of the bonus points mechanism 2_5
//  PortionSize - Number - Number of records to be processed
// 
// Returns:
//  QueryResult - The result of the request with the remaining overdue urgent bonus points
Function RequestResultBalancesOfOverdueUrgentBonusPoints(
	StartDateOfBonusPointsMechanism_2_5,
	PortionSize = Undefined)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1000
	|	BonusPoints.ValidityStartDate AS StartDateOfActionOfUrgentBonusPoints,
	|	BonusPoints.Period AS ExpirationDateOfUrgentBonusPoints,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	SUM(CASE
	|			WHEN BonusPoints.RecordType = &RecordTypeReceipt
	|				THEN BonusPoints.ToWriteOff
	|			ELSE -BonusPoints.ToWriteOff
	|		END) AS BalanceOfUrgentBonusPoints
	|INTO BalancesOfOverdueUrgentBonusPoints
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.DateToProcess >= &StartDateOfBonusPointsMechanism
	|	AND BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND BonusPoints.Period <= &CurrentDate
	|	AND BonusPoints.ToWriteOff <> 0
	|
	|GROUP BY
	|	BonusPoints.Period,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.ValidityStartDate
	|
	|INDEX BY
	|	Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalancesOfOverdueUrgentBonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BalancesOfOverdueUrgentBonusPoints.LoyaltyProgram.Description AS LoyaltyBonusProgramName,
	|	BalancesOfOverdueUrgentBonusPoints.Partner AS Partner,
	|	BalancesOfOverdueUrgentBonusPoints.Partner.Description AS PartnerName_,
	|	BalancesOfOverdueUrgentBonusPoints.StartDateOfActionOfUrgentBonusPoints AS StartDateOfActionOfUrgentBonusPoints,
	|	BalancesOfOverdueUrgentBonusPoints.ExpirationDateOfUrgentBonusPoints AS ExpirationDateOfUrgentBonusPoints,
	|	BalancesOfOverdueUrgentBonusPoints.BalanceOfUrgentBonusPoints AS BalanceOfUrgentBonusPoints
	|FROM
	|	BalancesOfOverdueUrgentBonusPoints AS BalancesOfOverdueUrgentBonusPoints
	|
	|ORDER BY
	|	PartnerName_,
	|	LoyaltyBonusProgramName,
	|	BalancesOfOverdueUrgentBonusPoints.StartDateOfActionOfUrgentBonusPoints
	|TOTALS BY
	|	LoyaltyProgram,
	|	Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner AS Partner,
	|	BonusPoints.Recorder AS Recorder,
	|	BonusPoints.DateToProcess AS DateToProcess,
	|	BonusPoints.ValidityStartDate AS ValidityStartDate,
	|	BonusPoints.Period AS Period,
	|	BonusPoints.ToWriteOff AS ToWriteOff
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.DateToProcess >= &StartDateOfBonusPointsMechanism
	|	AND BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|	AND BonusPoints.RecordType = &RecordTypeReceipt
	|	AND (BonusPoints.ValidityStartDate, BonusPoints.Period, BonusPoints.LoyaltyProgram, BonusPoints.Partner) IN
	|			(SELECT
	|				BalancesOfOverdueUrgentBonusPoints.StartDateOfActionOfUrgentBonusPoints,
	|				BalancesOfOverdueUrgentBonusPoints.ExpirationDateOfUrgentBonusPoints,
	|				BalancesOfOverdueUrgentBonusPoints.LoyaltyProgram,
	|				BalancesOfOverdueUrgentBonusPoints.Partner
	|			FROM
	|				BalancesOfOverdueUrgentBonusPoints AS BalancesOfOverdueUrgentBonusPoints)
	|
	|ORDER BY
	|	ValidityStartDate
	|TOTALS BY
	|	LoyaltyProgram,
	|	Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BonusPoints.Period,
	|	BonusPoints.Recorder,
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.LoyaltyProgram.Description AS LoyaltyBonusProgramName,
	|	BonusPoints.Partner,
	|	BonusPoints.Partner.Description AS PartnerName_,
	|	BonusPoints.ToWriteOff,
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.DateToProcess
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|	
	|	INNER JOIN BalancesOfOverdueUrgentBonusPoints AS BalancesOfOverdueUrgentBonusPoints
	|	ON BonusPoints.Partner = BalancesOfOverdueUrgentBonusPoints.Partner
	|		AND BonusPoints.LoyaltyProgram = BalancesOfOverdueUrgentBonusPoints.LoyaltyProgram
	|		AND BonusPoints.ValidityStartDate = BalancesOfOverdueUrgentBonusPoints.StartDateOfActionOfUrgentBonusPoints
	|		AND BonusPoints.Period = BalancesOfOverdueUrgentBonusPoints.ExpirationDateOfUrgentBonusPoints
	|WHERE
	|	BonusPoints.DateToProcess >= &StartDateOfBonusPointsMechanism
	|	AND BonusPoints.DateToProcess <> DATETIME(1, 1, 1)
	|
	|ORDER BY
	|	PartnerName_,
	|	LoyaltyBonusProgramName,
	|	ValidityStartDate
	|TOTALS BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner";
	Query.SetParameter("StartDateOfBonusPointsMechanism", StartDateOfBonusPointsMechanism_2_5);
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("RecordTypeReceipt", AccumulationRecordType.Receipt);
	
	If PortionSize <> Undefined Then
		Query.Text = StrReplace(Query.Text , "TOP 1000", "FIRST " + Format(PortionSize, "NG=;"));
	EndIf;
	
	Return Query.ExecuteBatch();
	
EndFunction

// Writes off the balances of overdue urgent bonus points according to the register of PH Bonus points
// 
// Parameters:
//  RowTableOfBalancesToBeDebited - ValueTableRow - Data on the balances of expired bonus points to be debited
//  TableOfDocumentBalances - ValueTable - Table of documents for calculating overdue bonus points with balances
//  DataChanged1 - Boolean - Data change flag for correct counting of processed documents
// 
// Returns:
//  Array of ValueTableRow - Array of rows with zero remaining bonus points to delete
// 
Function WriteOffBalanceOfOverdueUrgentBonusPoints(
			RowTableOfBalancesToBeDebited,
			TableOfDocumentBalances,
			DataChanged1)
			
	BalanceOfOverdueUrgentBonusPoints = RowTableOfBalancesToBeDebited.BalanceOfUrgentBonusPoints;
	
	StartDateOfActionOfUrgentBonusPoints = RowTableOfBalancesToBeDebited.StartDateOfActionOfUrgentBonusPoints;
	ExpirationDateOfUrgentBonusPoints = RowTableOfBalancesToBeDebited.ExpirationDateOfUrgentBonusPoints;
	
	ZeroRowsOfBalancesToDelete = New Array;
	
	// Write off the balance of overdue urgent bonus points
	For Each RowTableOfBalancesForDocuments In TableOfDocumentBalances Do
		
		If BalanceOfOverdueUrgentBonusPoints = 0
			Or (RowTableOfBalancesForDocuments.ValidityStartDate <> StartDateOfActionOfUrgentBonusPoints
					And RowTableOfBalancesForDocuments.Period <> ExpirationDateOfUrgentBonusPoints
					And RowTableOfBalancesForDocuments.ValidityStartDate > ExpirationDateOfUrgentBonusPoints) Then
			Break;
		EndIf;
		
		If RowTableOfBalancesForDocuments.ValidityStartDate <> StartDateOfActionOfUrgentBonusPoints
			Or RowTableOfBalancesForDocuments.Period <> ExpirationDateOfUrgentBonusPoints Then
			Continue;
		EndIf;
		
		Recorder = RowTableOfBalancesForDocuments.Recorder;
		AmountToBeDebited_ = RowTableOfBalancesForDocuments.ToWriteOff;
		
		AmountOfOverdueUrgentBonusPointsToBeDebited = Min(BalanceOfOverdueUrgentBonusPoints, AmountToBeDebited_);
		BalanceOfOverdueUrgentBonusPoints = 
			BalanceOfOverdueUrgentBonusPoints - AmountOfOverdueUrgentBonusPointsToBeDebited;
		
		Block = New DataLock;
		
		LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
		LockItem.SetValue("Recorder", Recorder);
		
		Block.Lock();
		
		SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
		SetOfPHEntriesBonusPoints.Filter.Recorder.Value = Recorder;
		SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
		SetOfPHEntriesBonusPoints.Read();
		
		StringRecordsetPHBonusPoints = SetOfPHEntriesBonusPoints.Add();
		FillPropertyValues(
			StringRecordsetPHBonusPoints,
			RowTableOfBalancesForDocuments);
		
		StringRecordsetPHBonusPoints.RecordType = AccumulationRecordType.Receipt;
		StringRecordsetPHBonusPoints.Accrued = -AmountOfOverdueUrgentBonusPointsToBeDebited;
		StringRecordsetPHBonusPoints.ToWriteOff = -AmountOfOverdueUrgentBonusPointsToBeDebited;
		StringRecordsetPHBonusPoints.DateToProcess = CurrentSessionDate();
		
		SetOfPHEntriesBonusPoints.Write();
		
		RowTableOfBalancesForDocuments.ToWriteOff = RowTableOfBalancesForDocuments.ToWriteOff - AmountOfOverdueUrgentBonusPointsToBeDebited;
		If RowTableOfBalancesForDocuments.ToWriteOff = 0 Then
			ZeroRowsOfBalancesToDelete.Add(RowTableOfBalancesForDocuments);
		EndIf;
		
		DataChanged1 = True;
		
	EndDo;
	
	Return ZeroRowsOfBalancesToDelete;
	
EndFunction

// Removes documents from further processing of the distribution of urgent bonus points
// 
// Parameters:
//  RowTableOfBalancesToBeDebited - ValueTableRow - Data on the balances of expired bonus points to be debited
//  TableOfDocumentsToBeRemovedFromProcessing - ValueTable - Table of documents for cancellation of the status of processing
//  DataChanged1 - Boolean - Data change flag for correct counting of processed documents
// 
// Returns:
//  Array of ValueTableRow - Array of rows with zero remaining bonus points to delete
// 
Function RemoveDocumentsFromStatusForProcessing(
			RowTableOfBalancesToBeDebited,
			TableOfDocumentsToBeRemovedFromProcessing,
			DataChanged1)
			
	StartDateOfActionOfUrgentBonusPoints = RowTableOfBalancesToBeDebited.StartDateOfActionOfUrgentBonusPoints;
	ExpirationDateOfUrgentBonusPoints = RowTableOfBalancesToBeDebited.ExpirationDateOfUrgentBonusPoints;
	
	Partner  = RowTableOfBalancesToBeDebited.Partner;
	LoyaltyProgram  = RowTableOfBalancesToBeDebited.LoyaltyProgram;
	
	ZeroRowsOfBalancesToDelete = New Array;
	
	For Each RowTableOfDocumentsToBeRemovedFromProcessing In TableOfDocumentsToBeRemovedFromProcessing Do
		
		AccrualAmountToBeWithdrawnFromProcessing = RowTableOfDocumentsToBeRemovedFromProcessing.ToWriteOff;
		AmountToWriteOffForWithdrawalFromProcessing = RowTableOfDocumentsToBeRemovedFromProcessing.ToWriteOff;
		
		Recorder = RowTableOfDocumentsToBeRemovedFromProcessing.Recorder;
		
		Block = New DataLock;
		
		LockItem = Block.Add("AccumulationRegister.BonusPoints.RecordSet");
		LockItem.SetValue("Recorder", Recorder);
		
		Block.Lock();
		
		SetOfPHEntriesBonusPoints = AccumulationRegisters.BonusPoints.CreateRecordSet();
		SetOfPHEntriesBonusPoints.Filter.Recorder.Value = Recorder;
		SetOfPHEntriesBonusPoints.Filter.Recorder.Use = True;
		SetOfPHEntriesBonusPoints.Read();
		
		For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
			
			If StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1) Then
				Continue;
			EndIf;
			
			// Remove the refund of the urgent bonus points from further processing
			// Movement on the resource is accrued
			If StringRecordsetPHBonusPoints.LoyaltyProgram = LoyaltyProgram
				And StringRecordsetPHBonusPoints.Partner = Partner
				And StringRecordsetPHBonusPoints.RecordType = AccumulationRecordType.Expense
				And StringRecordsetPHBonusPoints.Accrued < 0
				And StringRecordsetPHBonusPoints.ToWriteOff = 0 Then
			
				StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
				
				If ZeroRowsOfBalancesToDelete.Find(RowTableOfDocumentsToBeRemovedFromProcessing) = Undefined Then
					ZeroRowsOfBalancesToDelete.Add(RowTableOfDocumentsToBeRemovedFromProcessing);
				EndIf;
				
				DataChanged1 = True;
				
				Continue;
				
			EndIf;
			
			// Remove the expense of urgent bonus points from further processing
			// Movement on the resource is accrued
			If StringRecordsetPHBonusPoints.LoyaltyProgram = LoyaltyProgram
				And StringRecordsetPHBonusPoints.Partner = Partner
				And StringRecordsetPHBonusPoints.RecordType = AccumulationRecordType.Expense
				And StringRecordsetPHBonusPoints.Accrued > 0
				And StringRecordsetPHBonusPoints.ToWriteOff = 0 Then
			
				StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
				
				If ZeroRowsOfBalancesToDelete.Find(RowTableOfDocumentsToBeRemovedFromProcessing) = Undefined Then
					ZeroRowsOfBalancesToDelete.Add(RowTableOfDocumentsToBeRemovedFromProcessing);
				EndIf;
				
				DataChanged1 = True;
				
				Continue;
				
			EndIf;
			
			// Withdrawal of write-off of urgent bonus points from further processing
			// Movement on the resource to the writing
			If StringRecordsetPHBonusPoints.LoyaltyProgram = LoyaltyProgram
				And StringRecordsetPHBonusPoints.Partner = Partner
				And StringRecordsetPHBonusPoints.ValidityStartDate = StartDateOfActionOfUrgentBonusPoints
				And StringRecordsetPHBonusPoints.Period = ExpirationDateOfUrgentBonusPoints
				And StringRecordsetPHBonusPoints.ToWriteOff = AmountToWriteOffForWithdrawalFromProcessing
				And StringRecordsetPHBonusPoints.Accrued = 0 Then
				
				StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
				
				If ZeroRowsOfBalancesToDelete.Find(RowTableOfDocumentsToBeRemovedFromProcessing) = Undefined Then
					ZeroRowsOfBalancesToDelete.Add(RowTableOfDocumentsToBeRemovedFromProcessing);
				EndIf;
				
				AmountToWriteOffForWithdrawalFromProcessing = 0;
				DataChanged1 = True;
				
				Continue;
				
			EndIf;
			
			// Withdrawal of accrual of urgent bonus points from further processing
			// Movement on the resource is accrued
			// You only need to write off the accrual amount (there may be several terms with the same start period,
			// but different end periods and vice versa)
			If StringRecordsetPHBonusPoints.LoyaltyProgram = LoyaltyProgram
				And StringRecordsetPHBonusPoints.Partner = Partner
				And StringRecordsetPHBonusPoints.ValidityStartDate = StartDateOfActionOfUrgentBonusPoints
				And StringRecordsetPHBonusPoints.Period = StartDateOfActionOfUrgentBonusPoints
				And StringRecordsetPHBonusPoints.Accrued = AccrualAmountToBeWithdrawnFromProcessing
				And StringRecordsetPHBonusPoints.ToWriteOff = 0 Then
				
				StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
				
				If ZeroRowsOfBalancesToDelete.Find(RowTableOfDocumentsToBeRemovedFromProcessing) = Undefined Then
					ZeroRowsOfBalancesToDelete.Add(RowTableOfDocumentsToBeRemovedFromProcessing);
				EndIf;
				
				AccrualAmountToBeWithdrawnFromProcessing = 0;
				DataChanged1 = True;
				
				Continue;
				
			EndIf;
			
			// Remove write-off of overdue points from further processing
			If StringRecordsetPHBonusPoints.LoyaltyProgram = LoyaltyProgram
				And StringRecordsetPHBonusPoints.Partner = Partner
				And StringRecordsetPHBonusPoints.ValidityStartDate = StartDateOfActionOfUrgentBonusPoints
				And StringRecordsetPHBonusPoints.Period = ExpirationDateOfUrgentBonusPoints
				And StringRecordsetPHBonusPoints.Accrued <> 0
				And  StringRecordsetPHBonusPoints.ToWriteOff <> 0 Then
				
				StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
				
				If ZeroRowsOfBalancesToDelete.Find(RowTableOfDocumentsToBeRemovedFromProcessing) = Undefined Then
					ZeroRowsOfBalancesToDelete.Add(RowTableOfDocumentsToBeRemovedFromProcessing);
				EndIf;
				
				DataChanged1 = True;
				
			EndIf;
			
		EndDo;
		
		// We will remove from processing the amounts that were partially distributed
		For Each StringRecordsetPHBonusPoints In SetOfPHEntriesBonusPoints Do
			If StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1) Then
				Continue;
			EndIf;
			
			// Withdrawal of write-off of urgent bonus points from further processing
			// Movement on the resource to the writing
			If StringRecordsetPHBonusPoints.LoyaltyProgram = LoyaltyProgram
				And StringRecordsetPHBonusPoints.Partner = Partner
				And StringRecordsetPHBonusPoints.ValidityStartDate = StartDateOfActionOfUrgentBonusPoints
				And StringRecordsetPHBonusPoints.Period = ExpirationDateOfUrgentBonusPoints
				And AmountToWriteOffForWithdrawalFromProcessing <> 0 Then
				
				If StringRecordsetPHBonusPoints.ToWriteOff = AmountToWriteOffForWithdrawalFromProcessing Then
					StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
					
					If ZeroRowsOfBalancesToDelete.Find(RowTableOfDocumentsToBeRemovedFromProcessing) = Undefined Then
						ZeroRowsOfBalancesToDelete.Add(RowTableOfDocumentsToBeRemovedFromProcessing);
					EndIf;
					
					AmountToWriteOffForWithdrawalFromProcessing = 0;
					DataChanged1 = True;
					
				Else
					
					AmountToWithdrawFromProcessing = Min(
						AmountToWriteOffForWithdrawalFromProcessing,
						StringRecordsetPHBonusPoints.ToWriteOff);
						
					RowRecordsetPHBonusPointsNew = SetOfPHEntriesBonusPoints.Add();
					FillPropertyValues(
						RowRecordsetPHBonusPointsNew,
						StringRecordsetPHBonusPoints);
					
					StringRecordsetPHBonusPoints.Accrued = StringRecordsetPHBonusPoints.ToWriteOff - AmountToWithdrawFromProcessing;
						
					RowRecordsetPHBonusPointsNew.RecordType = AccumulationRecordType.Receipt;
					RowRecordsetPHBonusPointsNew.ToWriteOff = AmountToWithdrawFromProcessing;
					RowRecordsetPHBonusPointsNew.DateToProcess = Date(1, 1, 1);
					
					If ZeroRowsOfBalancesToDelete.Find(RowTableOfDocumentsToBeRemovedFromProcessing) = Undefined Then
						ZeroRowsOfBalancesToDelete.Add(RowTableOfDocumentsToBeRemovedFromProcessing);
					EndIf;
					
					AmountToWriteOffForWithdrawalFromProcessing = AmountToWriteOffForWithdrawalFromProcessing - AmountToWithdrawFromProcessing;
					DataChanged1 = True;
					
				EndIf;
				
				Continue;
				
			EndIf;
			
			// Withdrawal of accrual of urgent bonus points from further processing
			// Movement on the resource is accrued
			If StringRecordsetPHBonusPoints.LoyaltyProgram = LoyaltyProgram
				And StringRecordsetPHBonusPoints.Partner = Partner
				And StringRecordsetPHBonusPoints.ValidityStartDate = StartDateOfActionOfUrgentBonusPoints
				And StringRecordsetPHBonusPoints.Period = StartDateOfActionOfUrgentBonusPoints
				And AccrualAmountToBeWithdrawnFromProcessing <> 0 Then
				
				If StringRecordsetPHBonusPoints.Accrued = AccrualAmountToBeWithdrawnFromProcessing Then
					StringRecordsetPHBonusPoints.DateToProcess = Date(1, 1, 1);
					
					If ZeroRowsOfBalancesToDelete.Find(RowTableOfDocumentsToBeRemovedFromProcessing) = Undefined Then
						ZeroRowsOfBalancesToDelete.Add(RowTableOfDocumentsToBeRemovedFromProcessing);
					EndIf;
					
					AccrualAmountToBeWithdrawnFromProcessing = 0;
					DataChanged1 = True;
					
				Else
					
					AmountToWithdrawFromProcessing = Min(
						AccrualAmountToBeWithdrawnFromProcessing,
						StringRecordsetPHBonusPoints.Accrued);
						
					RowRecordsetPHBonusPointsNew = SetOfPHEntriesBonusPoints.Add();
					FillPropertyValues(
						RowRecordsetPHBonusPointsNew,
						StringRecordsetPHBonusPoints);
					
					StringRecordsetPHBonusPoints.Accrued = StringRecordsetPHBonusPoints.Accrued - AmountToWithdrawFromProcessing;
						
					RowRecordsetPHBonusPointsNew.RecordType = AccumulationRecordType.Receipt;
					RowRecordsetPHBonusPointsNew.Accrued = AmountToWithdrawFromProcessing;
					RowRecordsetPHBonusPointsNew.DateToProcess = Date(1, 1, 1);
					
					If ZeroRowsOfBalancesToDelete.Find(RowTableOfDocumentsToBeRemovedFromProcessing) = Undefined Then
						ZeroRowsOfBalancesToDelete.Add(RowTableOfDocumentsToBeRemovedFromProcessing);
					EndIf;
					
					AccrualAmountToBeWithdrawnFromProcessing = AccrualAmountToBeWithdrawnFromProcessing - AmountToWithdrawFromProcessing;
					DataChanged1 = True;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If DataChanged1 Then
			SetOfPHEntriesBonusPoints.Write();
		EndIf;
		
	EndDo;
	
	Return ZeroRowsOfBalancesToDelete;
	
EndFunction

#EndRegion

Procedure FillInBonusPointsReturnItemsFromCustomer(CurrentObject) Export
	
	SetPrivilegedMode(True);
	
	CurrentObject.BonusPointAccrual.Clear();
	CurrentObject.PaymentWithBonusPoints.Clear();
	
	If TypeOf(CurrentObject) = Type("DocumentObject.ReturnOfGoodsFromCustomer") Then
		DocumentBasis = CurrentObject.DocumentSalesOfGoodsAndServices;
		
		If TypeOf(DocumentBasis) = Type("DocumentRef.RetailSalesReport") Then
			QueryText = RequestTextRefundOfBonusPointsRetailSales();
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
			QueryText = RequestTextRefundOfBonusPointsWholesale();
		Else
			Return;
		EndIf;
	ElsIf TypeOf(CurrentObject) = Type("DocumentObject.SaleAdjustment") Then
		DocumentBasis = CurrentObject.DocumentBasis;
		
		If TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") 
			Or TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
			QueryText = RequestTextRefundOfBonusPointsWholesale();
		Else
			Return;
		EndIf;
	Else
		Return;
	EndIf;

	Query = New Query;
	Query.Text = QueryText;

	If TypeOf(CurrentObject) = Type("DocumentObject.ReturnOfGoodsFromCustomer") Then
		Query.SetParameter("ReturnDocumentLink", CurrentObject.Ref);
		Query.SetParameter("DocumentLinkCorrection", Documents.SaleAdjustment.EmptyRef());
		Query.SetParameter("Goods", CurrentObject.Goods.Unload(,"Products, Characteristic, Sum"));
	Else
		Query.SetParameter("DocumentLinkCorrection", CurrentObject.Ref);
		Query.SetParameter("ReturnDocumentLink", Documents.ReturnOfGoodsFromCustomer.EmptyRef());
		
		Goods = CurrentObject.Discrepancies.Unload(,"Products, Characteristic, Sum");
		
		If Goods.Total("Sum") >= 0 Then
			Return;
		EndIf;
		
		Query.SetParameter("Goods", Goods);
	EndIf;
		
	Query.Parameters.Insert("CurCurrentDocumentLink", CurrentObject.Ref);
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("DocumentCurrency", CurrentObject.Currency);
	Query.SetParameter("Date", CurrentObject.Date);
	Query.SetParameter("Partner", CurrentObject.Partner);

	Results = Query.ExecuteBatch();
	
	BalancesOfAccruedBonusPoints = Results[1].Unload();
	BalancesOfDebitedBonusPoints = Results[2].Unload();
	
	AmountOfPointsToBeRefunded = 0;
	AmountOfDebitedBonusPointsToBeRefunded = 0;
	
	SampleProducts_ = Results[3].Select();
	If SampleProducts_.Next() Then
		
		If SampleProducts_.Sum <> 0 Then
			AmountOfPointsToBeRefunded = BalancesOfAccruedBonusPoints.Total("AmountOfBonusPoints")
			                                * SampleProducts_.AmountInDocument / SampleProducts_.Sum;
			
			AmountOfDebitedBonusPointsToBeRefunded = BalancesOfDebitedBonusPoints.Total("AmountOfBonusPoints")
			                                      * SampleProducts_.AmountInDocument / SampleProducts_.Sum;
			
		EndIf;
		
	EndIf;
	
	For Each TSRow In BalancesOfAccruedBonusPoints Do
		
		If AmountOfPointsToBeRefunded = 0 Then
			Break;
		EndIf;
		
		If AmountOfPointsToBeRefunded >= TSRow.AmountOfBonusPoints Then
			
			AmountOfPointsToBeRefunded = AmountOfPointsToBeRefunded - TSRow.AmountOfBonusPoints;
			ToWriteOff = TSRow.AmountOfBonusPoints;
			
		Else
			
			ToWriteOff = AmountOfPointsToBeRefunded;
			AmountOfPointsToBeRefunded = 0;
			
		EndIf;
		
		NewRow = CurrentObject.BonusPointAccrual.Add();
		FillPropertyValues(NewRow, TSRow, "LoyaltyProgram, AccrualDate, DateOfDeduction");
		NewRow.AmountOfBonusPoints = ToWriteOff;
		
		TSRow.AmountOfBonusPoints = TSRow.AmountOfBonusPoints - ToWriteOff;
		
	EndDo;
	
	For Each TSRow In BalancesOfDebitedBonusPoints Do
		
		If AmountOfDebitedBonusPointsToBeRefunded = 0 Then
			Break;
		EndIf;
		
		If AmountOfDebitedBonusPointsToBeRefunded >= TSRow.AmountOfBonusPoints Then
			
			AmountOfDebitedBonusPointsToBeRefunded = AmountOfDebitedBonusPointsToBeRefunded - TSRow.AmountOfBonusPoints;
			ToWriteOff = TSRow.AmountOfBonusPoints;
			
		Else
			
			ToWriteOff = AmountOfDebitedBonusPointsToBeRefunded;
			AmountOfDebitedBonusPointsToBeRefunded = 0;
			
		EndIf;
		
		NewRow = CurrentObject.PaymentWithBonusPoints.Add();
		FillPropertyValues(NewRow, TSRow, "LoyaltyProgram, PayDate");
		NewRow.AmountOfBonusPoints = -ToWriteOff;
		
		TSRow.AmountOfBonusPoints = TSRow.AmountOfBonusPoints - ToWriteOff;
		
	EndDo;
	
EndProcedure

Function RequestTextRefundOfBonusPointsRetailSales()

	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Sum
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LoyaltyProgram,
	|	Table.AccrualDate AS AccrualDate,
	|	Table.DateOfDeduction AS DateOfDeduction,
	|	SUM(Table.AmountOfBonusPoints) AS AmountOfBonusPoints
	|FROM
	|	(SELECT
	|		BonusPointsTable.LoyaltyProgram AS LoyaltyProgram,
	|		BonusPointsTable.AccrualDate AS AccrualDate,
	|		BonusPointsTable.DateOfDeduction AS DateOfDeduction,
	|		BonusPointsTable.AmountOfBonusPoints AS AmountOfBonusPoints
	|	FROM
	|		Document.RetailSalesReport.BonusPointAccrual AS BonusPointsTable
	|	WHERE
	|		BonusPointsTable.Ref = &DocumentBasis
	|		AND BonusPointsTable.Partner = &Partner
	|		AND BonusPointsTable.Ref.Posted
	|		AND BonusPointsTable.AmountOfBonusPoints > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BonusPointsTable.LoyaltyProgram,
	|		BonusPointsTable.AccrualDate,
	|		BonusPointsTable.DateOfDeduction,
	|		-BonusPointsTable.AmountOfBonusPoints
	|	FROM
	|		Document.ReturnOfGoodsFromCustomer.BonusPointAccrual AS BonusPointsTable
	|	WHERE
	|		BonusPointsTable.Ref.DocumentSalesOfGoodsAndServices = &DocumentBasis
	|		AND BonusPointsTable.Ref.Partner = &Partner
	|		AND BonusPointsTable.Ref.Posted
	|		AND BonusPointsTable.AmountOfBonusPoints > 0
	|		AND BonusPointsTable.Ref.Ref <> &ReturnDocumentLink) AS Table
	|
	|GROUP BY
	|	Table.LoyaltyProgram,
	|	Table.AccrualDate,
	|	Table.DateOfDeduction
	|
	|HAVING
	|	SUM(Table.AmountOfBonusPoints) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LoyaltyProgram,
	|	Table.PayDate AS PayDate,
	|	SUM(Table.AmountOfBonusPoints) AS AmountOfBonusPoints
	|FROM
	|	(SELECT
	|		BonusPointsTable.LoyaltyProgram AS LoyaltyProgram,
	|		BonusPointsTable.PayDate AS PayDate,
	|		BonusPointsTable.AmountOfBonusPoints AS AmountOfBonusPoints
	|	FROM
	|		Document.RetailSalesReport.PaymentWithBonusPoints AS BonusPointsTable
	|	WHERE
	|		BonusPointsTable.Ref = &DocumentBasis
	|		AND BonusPointsTable.Partner = &Partner
	|		AND BonusPointsTable.Ref.Posted
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BonusPointsTable.LoyaltyProgram,
	|		BonusPointsTable.PayDate,
	|		-BonusPointsTable.AmountOfBonusPoints
	|	FROM
	|		Document.ReturnOfGoodsFromCustomer.PaymentWithBonusPoints AS BonusPointsTable
	|	WHERE
	|		BonusPointsTable.Ref.DocumentSalesOfGoodsAndServices = &DocumentBasis
	|		AND BonusPointsTable.Ref.Partner = &Partner
	|		AND BonusPointsTable.Ref.Posted
	|		AND BonusPointsTable.Ref.Ref <> &ReturnDocumentLink) AS Table
	|
	|GROUP BY
	|	Table.LoyaltyProgram,
	|	Table.PayDate
	|
	|HAVING
	|	SUM(Table.AmountOfBonusPoints) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SUM(Goods.Sum), 0) AS Sum,
	|	ISNULL(SUM(Goods.AmountInDocument), 0) AS AmountInDocument
	|FROM
	|	(SELECT
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Sum AS Sum,
	|		0 AS AmountInDocument
	|	FROM
	|		Document.RetailSalesReport.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &DocumentBasis
	|		AND GoodsTable.Ref.Posted
	|		AND GoodsTable.Partner = &Partner
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Products,
	|		Goods.Characteristic,
	|		0,
	|		Goods.Sum
	|	FROM
	|		Goods AS Goods) AS Goods
	|";
	
	Return QueryText
	
EndFunction

Function RequestTextRefundOfBonusPointsWholesale()
	
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Sum
	|INTO GoodsTS
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LoyaltyProgram AS LoyaltyProgram,
	|	Table.AccrualDate AS AccrualDate,
	|	Table.DateOfDeduction AS DateOfDeduction,
	|	SUM(Table.AmountOfBonusPoints) AS AmountOfBonusPoints
	|FROM
	|	(SELECT
	|		BonusPointsTable.LoyaltyProgram AS LoyaltyProgram,
	|		BonusPointsTable.AccrualDate AS AccrualDate,
	|		BonusPointsTable.DateOfDeduction AS DateOfDeduction,
	|		BonusPointsTable.AmountOfBonusPoints AS AmountOfBonusPoints
	|	FROM
	|		Document.CustomerInvoice.BonusPointAccrual AS BonusPointsTable
	|	WHERE
	|		BonusPointsTable.Ref = &DocumentBasis
	|		AND BonusPointsTable.Ref.Posted
	|		AND BonusPointsTable.AmountOfBonusPoints > 0
	|
	|	UNION ALL
	|
	|	SELECT 
	|		BonusPointsTable.LoyaltyProgram,
	|		BonusPointsTable.AccrualDate,
	|		BonusPointsTable.DateOfDeduction,
	|		BonusPointsTable.AmountOfBonusPoints
	|	FROM
	|		Document.CustomerInvoiceServices.BonusPointAccrual AS BonusPointsTable
	|	WHERE
	|		BonusPointsTable.Ref = &DocumentBasis
	|		AND BonusPointsTable.Ref.Posted
	|		AND BonusPointsTable.AmountOfBonusPoints > 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		BonusPointsTable.LoyaltyProgram,
	|		BonusPointsTable.AccrualDate,
	|		BonusPointsTable.DateOfDeduction,
	|		-BonusPointsTable.AmountOfBonusPoints
	|	FROM
	|		Document.ReturnOfGoodsFromCustomer.BonusPointAccrual AS BonusPointsTable
	|	WHERE
	|		BonusPointsTable.Ref.DocumentSalesOfGoodsAndServices = &DocumentBasis
	|		AND BonusPointsTable.Ref.Partner = &Partner
	|		AND BonusPointsTable.Ref.Posted
	|		AND BonusPointsTable.AmountOfBonusPoints > 0
	|		AND BonusPointsTable.Ref.Ref <> &ReturnDocumentLink
	|
	|	UNION ALL
	|
	|	SELECT
	|		BonusPointsTable.LoyaltyProgram,
	|		BonusPointsTable.AccrualDate,
	|		BonusPointsTable.DateOfDeduction,
	|		-BonusPointsTable.AmountOfBonusPoints
	|	FROM
	|		Document.SaleAdjustment.BonusPointAccrual AS BonusPointsTable
	|	WHERE
	|		BonusPointsTable.Ref.DocumentBasis = &DocumentBasis
	|		AND (BonusPointsTable.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods)
	|			OR BonusPointsTable.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|			OR BonusPointsTable.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection))
	|		AND BonusPointsTable.Ref.Partner = &Partner
	|		AND BonusPointsTable.Ref.Posted
	|		AND BonusPointsTable.AmountOfBonusPoints > 0
	|		AND BonusPointsTable.Ref.Ref <> &DocumentLinkCorrection) AS Table
	|GROUP BY
	|	Table.LoyaltyProgram,
	|	Table.AccrualDate,
	|	Table.DateOfDeduction
	|HAVING
	|	SUM(Table.AmountOfBonusPoints) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LoyaltyProgram AS LoyaltyProgram,
	|	Table.PayDate AS PayDate,
	|	SUM(Table.AmountOfBonusPoints) AS AmountOfBonusPoints
	|FROM
	|	(SELECT
	|		CustomerInvoice.LoyaltyCard.Owner.LoyaltyProgram AS LoyaltyProgram,
	|		BEGINOFPERIOD(CustomerInvoice.Date, DAY) AS PayDate,
	|		BonusPointsTable.AmountOfBonusPointsToDeduction AS AmountOfBonusPoints
	|	FROM
	|		Document.CustomerInvoice.Goods AS BonusPointsTable
	|			LEFT JOIN Document.CustomerInvoice AS CustomerInvoice
	|			ON BonusPointsTable.Ref = CustomerInvoice.Ref
	|	WHERE
	|		BonusPointsTable.Ref = &DocumentBasis
	|		AND CustomerInvoice.Partner = &Partner
	|		AND BonusPointsTable.Ref.Posted
	|		AND NOT CustomerInvoice.LoyaltyCard.Owner.LoyaltyProgram IS NULL
	|
	|	UNION ALL
	|
	|	SELECT 
	|		CustomerInvoiceServices.LoyaltyCard.Owner.LoyaltyProgram,
	|		BEGINOFPERIOD(CustomerInvoiceServices.Date, DAY),
	|		BonusPointsTable.AmountOfBonusPointsToDeduction
	|	FROM
	|		Document.CustomerInvoiceServices.Services AS BonusPointsTable
	|			LEFT JOIN Document.CustomerInvoiceServices AS CustomerInvoiceServices
	|			ON BonusPointsTable.Ref = CustomerInvoiceServices.Ref
	|	WHERE
	|		BonusPointsTable.Ref = &DocumentBasis
	|		AND CustomerInvoiceServices.Partner = &Partner
	|		AND BonusPointsTable.Ref.Posted
	|		AND NOT CustomerInvoiceServices.LoyaltyCard.Owner.LoyaltyProgram IS NULL
	|
	|	UNION ALL
	|
	|	SELECT
	|		BonusPointsTable.LoyaltyProgram,
	|		BonusPointsTable.PayDate,
	|		BonusPointsTable.AmountOfBonusPoints
	|	FROM
	|		Document.ReturnOfGoodsFromCustomer.PaymentWithBonusPoints AS BonusPointsTable
	|	WHERE
	|		BonusPointsTable.Ref.DocumentSalesOfGoodsAndServices = &DocumentBasis
	|		AND BonusPointsTable.Ref.Partner = &Partner
	|		AND BonusPointsTable.Ref.Posted
	|		AND BonusPointsTable.Ref <> &ReturnDocumentLink
	|
	|	UNION ALL
	|
	|	SELECT
	|		BonusPointsTable.LoyaltyProgram,
	|		BonusPointsTable.PayDate,
	|		BonusPointsTable.AmountOfBonusPoints
	|	FROM
	|		Document.SaleAdjustment.PaymentWithBonusPoints AS BonusPointsTable
	|	WHERE
	|		BonusPointsTable.Ref.DocumentBasis = &DocumentBasis
	|		AND (BonusPointsTable.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods)
	|			OR BonusPointsTable.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|			OR BonusPointsTable.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection))
	|		AND BonusPointsTable.Ref.Partner = &Partner
	|		AND BonusPointsTable.Ref.Posted
	|		AND BonusPointsTable.Ref <> &DocumentLinkCorrection) AS Table
	|GROUP BY
	|	Table.LoyaltyProgram,
	|	Table.PayDate
	|HAVING
	|	SUM(Table.AmountOfBonusPoints) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SUM(Goods.Sum), 0) AS Sum,
	|	ISNULL(SUM(Goods.AmountInDocument), 0) AS AmountInDocument
	|FROM
	|	(SELECT
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Sum AS Sum,
	|		0 AS AmountInDocument
	|	FROM
	|		Document.CustomerInvoice.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &DocumentBasis
	|		AND GoodsTable.Ref.Posted
	|
	|	UNION ALL
	|
	|	SELECT 
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Sum AS Sum,
	|		0 AS AmountInDocument
	|	FROM
	|		Document.CustomerInvoiceServices.Services AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &DocumentBasis
	|		AND GoodsTable.Ref.Posted
	|
	|	UNION ALL
	|
	|	SELECT
	|		Goods.Products,
	|		Goods.Characteristic,
	|		0,
	|		Goods.Sum
	|	FROM
	|		GoodsTS AS Goods
	|	WHERE 
	|		VALUETYPE(&CurCurrentDocumentLink) = TYPE(Document.ReturnOfGoodsFromCustomer)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Goods.Products,
	|		Goods.Characteristic,
	|		0,
	|		Goods.Sum*(-1)
	|	FROM
	|		GoodsTS AS Goods
	|	WHERE
	|		VALUETYPE(&CurCurrentDocumentLink) = TYPE(Document.SaleAdjustment)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Goods.Products,
	|		Goods.Characteristic,
	|		-Goods.Sum,
	|		0
	|	FROM
	|		Document.ReturnOfGoodsFromCustomer.Goods AS Goods
	|	WHERE
	|		Goods.Ref.DocumentSalesOfGoodsAndServices = &DocumentBasis
	|		AND Goods.Ref.Partner = &Partner
	|		AND Goods.Ref.Posted
	|		AND Goods.Ref <> &ReturnDocumentLink
	|
	|	UNION ALL
	|
	|	SELECT
	|		Goods.Products,
	|		Goods.Characteristic,
	|		Goods.Sum,
	|		0
	|	FROM
	|		Document.SaleAdjustment.Discrepancies AS Goods
	|	WHERE
	|		Goods.Ref.DocumentBasis = &DocumentBasis
	|		AND (Goods.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods)
	|			OR Goods.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.AdjustmentUnderApprovalOfParties)
	|			OR Goods.Ref.AdjustmentKind = VALUE(Enum.BusinessTransactions.ErrorCorrection))
	|		AND Goods.Ref.Partner = &Partner
	|		AND Goods.Ref.Posted
	|		AND Goods.Ref <> &DocumentLinkCorrection
	|		AND Goods.Sum < 0 ) AS Goods";
	
	Return QueryText
	
EndFunction

Procedure FillInBonusPointsCheckCashRegisterRefund(CurrentObject) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	RelativeExchangeRatesSliceLast.Currency AS Currency,
	|	RelativeExchangeRatesSliceLast.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
	|INTO ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS RelativeExchangeRatesSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LoyaltyProgram,
	|	Table.AccrualDate AS AccrualDate,
	|	Table.DateOfDeduction,
	|	SUM(Table.AmountOfBonusPoints) AS AmountOfBonusPoints
	|INTO BonusPoints
	|FROM
	|	(SELECT
	|		CashRegisterReceiptBonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|		CashRegisterReceiptBonusPoints.AccrualDate AS AccrualDate,
	|		CashRegisterReceiptBonusPoints.DateOfDeduction AS DateOfDeduction,
	|		CashRegisterReceiptBonusPoints.AmountOfBonusPoints AS AmountOfBonusPoints
	|	FROM
	|		Document.CashRegisterReceipt.BonusPoints AS CashRegisterReceiptBonusPoints
	|	WHERE
	|		CashRegisterReceiptBonusPoints.Ref = &CashRegisterReceipt
	|		AND CashRegisterReceiptBonusPoints.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CashRegisterReceiptReturnBonusPoints.LoyaltyProgram,
	|		CashRegisterReceiptReturnBonusPoints.AccrualDate,
	|		CashRegisterReceiptReturnBonusPoints.DateOfDeduction,
	|		-CashRegisterReceiptReturnBonusPoints.AmountOfBonusPoints
	|	FROM
	|		Document.CashRegisterReceiptReturn.BonusPoints AS CashRegisterReceiptReturnBonusPoints
	|	WHERE
	|		CashRegisterReceiptReturnBonusPoints.Ref.CashRegisterReceipt = &CashRegisterReceipt
	|		AND CashRegisterReceiptReturnBonusPoints.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
	|		AND CashRegisterReceiptReturnBonusPoints.Ref.Ref <> &Ref) AS Table
	|
	|GROUP BY
	|	Table.LoyaltyProgram,
	|	Table.AccrualDate,
	|	Table.DateOfDeduction
	|
	|HAVING
	|	SUM(Table.AmountOfBonusPoints) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.AccrualDate AS AccrualDate,
	|	BonusPoints.DateOfDeduction AS DateOfDeduction,
	|	BonusPoints.AmountOfBonusPoints AS AmountOfBonusPoints,
	|	BonusPoints.AmountOfBonusPoints * ISNULL(CurrencyConversionRatesForBonuses.CourseNumerator, 1) * ISNULL(DocumentExchangeRates.CourseDenominator, 1) / (ISNULL(DocumentExchangeRates.CourseNumerator, 1) * ISNULL(CurrencyConversionRatesForBonuses.CourseDenominator, 1)) * BonusPoints.LoyaltyProgram.ConversionRateOfBonusesIntoCurrency AS AmountInDocumentCurrency
	|FROM
	|	BonusPoints AS BonusPoints
	|		LEFT JOIN ExchangeRates AS CurrencyConversionRatesForBonuses
	|		ON (CurrencyConversionRatesForBonuses.Currency = BonusPoints.LoyaltyProgram.BonusConversionCurrency)
	|		LEFT JOIN ExchangeRates AS DocumentExchangeRates
	|		ON (DocumentExchangeRates.Currency = &DocumentCurrency)
	|
	|ORDER BY
	|	AccrualDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	SUM(Goods.AmountOfBonusPointsToDeduction) AS AmountOfBonusPointsToDeduction,
	|	SUM(Goods.AmountOfEarnedBonusPointsInCurrency) AS AmountOfEarnedBonusPointsInCurrency,
	|	SUM(Goods.Count) AS Count,
	|	SUM(Goods.QuantityOfGoodsInDocument) AS QuantityOfGoodsInDocument
	|FROM
	|	(SELECT
	|		CashRegisterReceiptGoods.Products AS Products,
	|		CashRegisterReceiptGoods.Characteristic AS Characteristic,
	|		CashRegisterReceiptGoods.AmountOfBonusPointsToDeduction AS AmountOfBonusPointsToDeduction,
	|		CashRegisterReceiptGoods.AmountOfEarnedBonusPointsInCurrency AS AmountOfEarnedBonusPointsInCurrency,
	|		CashRegisterReceiptGoods.Count AS Count,
	|		0 AS QuantityOfGoodsInDocument
	|	FROM
	|		Document.CashRegisterReceipt.Goods AS CashRegisterReceiptGoods
	|	WHERE
	|		CashRegisterReceiptGoods.Ref = &CashRegisterReceipt
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Products,
	|		Goods.Characteristic,
	|		0,
	|		0,
	|		0,
	|		Goods.Count
	|	FROM
	|		Goods AS Goods) AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashRegisterReceipt.LoyaltyCard AS LoyaltyCard,
	|	CashRegisterReceipt.LoyaltyCard.Owner.LoyaltyProgram AS LoyaltyProgram,
	|	CashRegisterReceipt.Date AS Date
	|FROM
	|	Document.CashRegisterReceipt AS CashRegisterReceipt
	|WHERE
	|	CashRegisterReceipt.Ref = &CashRegisterReceipt;
	|";

	Query.SetParameter("Ref", CurrentObject.Ref);
	Query.SetParameter("CashRegisterReceipt", CurrentObject.CashRegisterReceipt);
	Query.SetParameter("Date",   CurrentObject.Date);
	Query.SetParameter("DocumentCurrency", CurrentObject.Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(CurrentObject.Organization));
	Query.SetParameter("Goods", CurrentObject.Goods.Unload());

	Results = Query.ExecuteBatch();
	
	BalanceBonusPoints = Results[3].Unload();
	
	AmountOfPointsToBeRefunded = 0;
	AmountOfDebitedBonusPointsToBeRefunded = 0;
	
	SampleProducts_ = Results[4].Select();
	While SampleProducts_.Next() Do
		
		If SampleProducts_.Count <> 0 Then
		
			AmountOfPointsToBeRefunded = AmountOfPointsToBeRefunded
			                                + SampleProducts_.AmountOfEarnedBonusPointsInCurrency
			                                * SampleProducts_.QuantityOfGoodsInDocument / SampleProducts_.Count;
			
			AmountOfDebitedBonusPointsToBeRefunded = AmountOfDebitedBonusPointsToBeRefunded
			                                      + SampleProducts_.AmountOfBonusPointsToDeduction
			                                      * SampleProducts_.QuantityOfGoodsInDocument / SampleProducts_.Count;
			
		EndIf;
		
	EndDo;
	
	CurrentObject.BonusPoints.Clear();
	
	For Each TSRow In BalanceBonusPoints Do
		
		If AmountOfPointsToBeRefunded = 0 Then
			Break;
		EndIf;
		
		If AmountOfPointsToBeRefunded >= TSRow.AmountInDocumentCurrency Then
			
			AmountOfPointsToBeRefunded = AmountOfPointsToBeRefunded - TSRow.AmountInDocumentCurrency;
			
			ToWriteOff = TSRow.AmountInDocumentCurrency;
			
			NewRow = CurrentObject.BonusPoints.Add();
			FillPropertyValues(NewRow, TSRow, "LoyaltyProgram, AccrualDate, DateOfDeduction");
			NewRow.AmountOfBonusPoints = TSRow.AmountOfBonusPoints *  ToWriteOff / TSRow.AmountInDocumentCurrency;
			
			TSRow.AmountInDocumentCurrency = TSRow.AmountInDocumentCurrency - ToWriteOff;
			TSRow.AmountOfBonusPoints = TSRow.AmountOfBonusPoints - NewRow.AmountOfBonusPoints;
			
		Else
			
			ToWriteOff = AmountOfPointsToBeRefunded;
			
			AmountOfPointsToBeRefunded = 0;
			
			NewRow = CurrentObject.BonusPoints.Add();
			FillPropertyValues(NewRow, TSRow, "LoyaltyProgram, AccrualDate, DateOfDeduction");
			NewRow.AmountOfBonusPoints = TSRow.AmountOfBonusPoints *  ToWriteOff / TSRow.AmountInDocumentCurrency;
			
			TSRow.AmountInDocumentCurrency = TSRow.AmountInDocumentCurrency - ToWriteOff;
			TSRow.AmountOfBonusPoints = TSRow.AmountOfBonusPoints - NewRow.AmountOfBonusPoints;
			
		EndIf;
		
	EndDo;
	
	Selection = Results[5].Select();
	If Selection.Next() Then
		CurrentObject.LoyaltyCard              = Selection.LoyaltyCard;
		CurrentObject.AmountOfBonusPointsToReturn = AmountOfDebitedBonusPointsToBeRefunded;
	EndIf;
	
EndProcedure

// Returns a table of bonus points for the table of discounts and margins
// 
// Parameters:
//  DiscountsMarkups - ValueTable - Table of discounts and surcharges
//  Date - Date - Start date of calculation of the bonus points validity period
// 
// Returns:
//  ValueTable - Bonus Points Table:
//   * LoyaltyProgram - CatalogRef.LoyaltyPrograms - Loyalty Program
//   * BonusConversionCurrency     - CatalogRef.Currencies - Bonus conversion currency
//   * ConversionRateOfBonusesIntoCurrency - Number - The conversion rate of bonuses in the currency
//   * ConnectionKey - String - Communication key
//   * DateOfDeduction - Date - Date of write-off
//   * AccrualDate - Date - Accrual date
//   * AmountOfBonusPoints - Number - The amount of bonus points
Function BonusPointsTable(DiscountsMarkups, Date) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Table.ConnectionKey AS ConnectionKey,
	|	Table.DiscountMarkup AS DiscountMarkup,
	|	Table.Sum AS Sum
	|INTO DiscountsMarkups
	|FROM
	|	&DiscountsMarkups AS Table
	|WHERE
	|	Table.DiscountApplicationMethod = VALUE(Enum.DiscountMarkupApplicationMethods.GrantBonusPoints)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
	|	TabularSection.LoyaltyProgram.BonusConversionCurrency AS BonusConversionCurrency,
	|	TabularSection.LoyaltyProgram.ConversionRateOfBonusesIntoCurrency AS ConversionRateOfBonusesIntoCurrency,
	|	TabularSection.ConnectionKey AS ConnectionKey,
	|
	|	CASE
	|		WHEN TabularSection.DiscountMarkup.NumberOfValidityPeriods > 0 THEN
	|			CASE
	|				WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.DAY)
	|					THEN DATEADD(TabularSection.Period, DAY, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|				WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.WEEK)
	|					THEN DATEADD(TabularSection.Period, WEEK, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|				WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.MONTH)
	|					THEN DATEADD(TabularSection.Period, MONTH, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|				WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.QUARTER)
	|					THEN DATEADD(TabularSection.Period, QUARTER, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|				WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.YEAR)
	|					THEN DATEADD(TabularSection.Period, YEAR, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|				WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.TENDAYS)
	|					THEN DATEADD(TabularSection.Period, TENDAYS, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|				WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.HALFYEAR)
	|					THEN DATEADD(TabularSection.Period, HALFYEAR, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|				ELSE TabularSection.Period
	|			END
	|	ELSE
	|		DATETIME(1,1,1)
	|	END AS DateOfDeduction,
	|
	|	CASE
	|		WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.DAY)
	|			THEN DATEADD(&Period, DAY, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|		WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.WEEK)
	|			THEN DATEADD(&Period, WEEK, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|		WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.MONTH)
	|			THEN DATEADD(&Period, MONTH, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|		WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.QUARTER)
	|			THEN DATEADD(&Period, QUARTER, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|		WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.YEAR)
	|			THEN DATEADD(&Period, YEAR, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|		WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.TENDAYS)
	|			THEN DATEADD(&Period, TENDAYS, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|		WHEN TabularSection.DiscountMarkup.PeriodOfActionStartDelay = VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN DATEADD(&Period, HALFYEAR, TabularSection.DiscountMarkup.NumberOfActionStartDelayPeriods)
	|		ELSE &Period
	|	END AS AccrualDate,
	|
	|	TabularSection.Sum AS AmountOfBonusPoints
	|
	|FROM
	|	(
	|	SELECT
	|		CASE
	|			WHEN TabularSection.DiscountMarkup.ActionPeriod = VALUE(Enum.Periodicity.DAY)
	|				THEN DATEADD(&Period, DAY, TabularSection.DiscountMarkup.NumberOfValidityPeriods)
	|				WHEN TabularSection.DiscountMarkup.ActionPeriod = VALUE(Enum.Periodicity.WEEK)
	|				THEN DATEADD(&Period, WEEK, TabularSection.DiscountMarkup.NumberOfValidityPeriods)
	|			WHEN TabularSection.DiscountMarkup.ActionPeriod = VALUE(Enum.Periodicity.MONTH)
	|				THEN DATEADD(&Period, MONTH, TabularSection.DiscountMarkup.NumberOfValidityPeriods)
	|			WHEN TabularSection.DiscountMarkup.ActionPeriod = VALUE(Enum.Periodicity.QUARTER)
	|				THEN DATEADD(&Period, QUARTER, TabularSection.DiscountMarkup.NumberOfValidityPeriods)
	|			WHEN TabularSection.DiscountMarkup.ActionPeriod = VALUE(Enum.Periodicity.YEAR)
	|				THEN DATEADD(&Period, YEAR, TabularSection.DiscountMarkup.NumberOfValidityPeriods)
	|			WHEN TabularSection.DiscountMarkup.ActionPeriod = VALUE(Enum.Periodicity.TENDAYS)
	|				THEN DATEADD(&Period, TENDAYS, TabularSection.DiscountMarkup.NumberOfValidityPeriods)
	|			WHEN TabularSection.DiscountMarkup.ActionPeriod = VALUE(Enum.Periodicity.HALFYEAR)
	|				THEN DATEADD(&Period, HALFYEAR, TabularSection.DiscountMarkup.NumberOfValidityPeriods)
	|			ELSE &Period
	|		END                                                    AS Period,
	|		TabularSection.DiscountMarkup.LoyaltyProgram AS LoyaltyProgram,
	|		TabularSection.Sum                                     AS Sum,
	|		TabularSection.DiscountMarkup                             AS DiscountMarkup,
	|		TabularSection.ConnectionKey                                 AS ConnectionKey
	|	FROM
	|		DiscountsMarkups AS TabularSection
	|	) AS TabularSection
	|";
	
	Query.SetParameter("DiscountsMarkups", DiscountsMarkups);
	Query.SetParameter("Period",        Date);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

Function AccrualAndWriteOffTable(AccrualRule, Date) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT
	|	AccrualRule.DataCompositionSchema AS DataCompositionSchema,
	|	AccrualRule.StorageOfDataCompositionSchema AS StorageOfDataCompositionSchema,
	|	AccrualRule.StorageOfDataCompositionSettings AS StorageOfDataCompositionSettings,
	|	AccrualRule.Owner AS LoyaltyProgram
	|FROM
	|	Catalog.CustomerRewardProgramRules AS AccrualRule
	|WHERE
	|	AccrualRule.Ref = &Ref");
	
	Query.SetParameter("Ref", AccrualRule);
	
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	
	If ValueIsFilled(Selection.DataCompositionSchema) Then
		DataCompositionSchema = Catalogs.CustomerRewardProgramRules.GetTemplate(Selection.DataCompositionSchema);
	Else
		SamplingDataLayoutSchemaStorage = Selection.StorageOfDataCompositionSchema; // ValueStorage
		DataCompositionSchema = SamplingDataLayoutSchemaStorage.Get();
	EndIf;
	
	SelectionStorageOfDataLayoutSettings = Selection.StorageOfDataCompositionSettings; // ValueStorage
	DataCompositionSettings = SelectionStorageOfDataLayoutSettings.Get();
	
	// Preparing a data layout layout builder, loading settings
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));

	If DataCompositionSettings <> Undefined Then
		SettingsComposer.LoadSettings(DataCompositionSettings);
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	Else
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;

	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);

	Parameter = SettingsComposer.Settings.DataParameters.Items.Find("CurrentDate");
	If Parameter <> Undefined Then
		Parameter.Use = True;
		Parameter.Value = Date;
	EndIf;

	Parameter = SettingsComposer.Settings.DataParameters.Items.Find("AutomaticAccrual");
	If Parameter <> Undefined Then
		Parameter.Use = True;
		Parameter.Value = AccrualRule;
	EndIf;

	Parameter = SettingsComposer.Settings.DataParameters.Items.Find("LoyaltyProgram");
	If Parameter <> Undefined Then
		Parameter.Use = True;
		Parameter.Value = Selection.LoyaltyProgram;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
		SettingsComposer.GetSettings(), , , Type("DataCompositionValueCollectionTemplateGenerator"), False);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,,,True);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;

	ReportData = New ValueTable();
	OutputProcessor.SetObject(ReportData);
	ReportData = OutputProcessor.Output(CompositionProcessor);

	Return ReportData;
	
EndFunction

#EndRegion
