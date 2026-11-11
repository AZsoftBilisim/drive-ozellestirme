
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SettlementStartDate 			= BegOfMonth(Parameters.SettlementStartDate);
	RegistrationPeriod 			= BegOfMonth(Parameters.RegistrationPeriod);
	ExplanationToChangeProhibition = Parameters.ExplanationToChangeProhibition; // ValueStorage
	ExplanationToChangeProhibition = ExplanationToChangeProhibition.Get();
	DecryptionOfLock 		= Parameters.DecryptionOfLock; // ValueStorage
	DecryptionOfLock 		= DecryptionOfLock.Get();
	DecryptionOfTasks			= Parameters.DecryptionOfTasks; // ValueStorage
	
	If Not ValueIsFilled(SettlementStartDate) Or Not ValueIsFilled(RegistrationPeriod)
	 Or Not TypeOf(ExplanationToChangeProhibition) = Type("ValueTable")
	 Or Not TypeOf(DecryptionOfLock) = Type("ValueTable") Then
		Raise NStr("vi = 'Ngữ cảnh mở biểu mẫu không hợp lệ';
					|ru = 'Некорректный контекст открытия формы';
					|en = 'Incorrect form opening context'; fa = 'Incorrect form opening context';
					|it = 'Contesto di apertura del modello è scorretto';
					|pl = 'Nieprawidłowy kontekst otwarcia formularzu';
					|tr = 'Form açma hatalı içerik'");
	EndIf;
	
	ThereAreBanDates     			  = False;
	ThereAreBlockingErrors  			  = Parameters.PeriodIsPartiallyBlocked;
	ThereAreAccountingPolicies 			  = True;
	ThereAreOrganizationsWithoutAccountingPolicies = False;
	
	// Fill in the table of prohibitions from the passed parameter
	For Each CurrRow In ExplanationToChangeProhibition Do
		
		If Not ValueIsFilled(CurrRow.AccountingPolicy) Then
			ThereAreOrganizationsWithoutAccountingPolicies = True;
		Else
			StartAccounting = Max(StartAccounting, CurrRow.AccountingPolicy);
		EndIf;
		
		NewRow = PeriodEndClosing.Add();
		FillPropertyValues(NewRow, CurrRow);
		
		NewRow.FirstPermittedPeriod = Max(CurrRow.RoutineOperations, CurrRow.Bookkeeping, CurrRow.FinancialAccounting);
		
		ThereAreBanDates   = ThereAreBanDates
			Or (NewRow.FirstPermittedPeriod > SettlementStartDate);
		ThereAreAccountingPolicies = ThereAreAccountingPolicies And Not ThereAreOrganizationsWithoutAccountingPolicies
			And (NewRow.AccountingPolicy <= SettlementStartDate Or Not NewRow.ThereAreRegisteredRecords);
			
		NewRow.RecalculationIsRequiredFrom = SettlementStartDate;
		
	EndDo;

	// Fill in the table of prohibitions from the passed parameter
	For Each CurrRow In DecryptionOfLock Do
		
		TableRow = PeriodEndClosing.FindRows(New Structure("Organization", CurrRow.Organization));
		If TableRow.Count() <> 1 Then
			Continue;
		EndIf;
		
		TableRow = TableRow[0];
		
		If ValueIsFilled(CurrRow.BlockingPeriod) Then
			TableRow.FirstUnblockedPeriod = EndOfMonth(CurrRow.BlockingPeriod) + 1;
		EndIf;
		
		If ValueIsFilled(CurrRow.TasksPeriod) And ValueIsFilled(CurrRow.BlockingPeriod) And CurrRow.TasksPeriod <= CurrRow.BlockingPeriod Then
			ThereAreBlockingErrors = True; // invalid blocking period, there are tasks
			TableRow.LockError = True;
			TableRow.FirstUnblockedPeriod = Date(1,1,1);
		ElsIf BegOfMonth(SettlementStartDate) <= CurrRow.BlockingPeriod Then
			TableRow.LockError = True;
		EndIf;
		
	EndDo;
	
	// We will adjust the visibility of the elements depending on the diagnosed problems.
	Items.PeriodEndClosingFirstPermittedPeriod.Visible 		 = ThereAreBanDates;
	Items.PeriodEndClosingFirstUnblockedPeriod.Visible = ThereAreBlockingErrors Or Parameters.IsPeriodLocked;
	Items.FormSetUpLockFromChanges.Visible 			 = (ThereAreBlockingErrors Or Parameters.IsPeriodLocked) And MonthEndTransactionsServer.YouHaveRightToManageBlockingOfPeriod();
	Items.PeriodEndClosingAccountingPolicy.Visible 		   		 = Not ThereAreAccountingPolicies;

	SettingBanDatesElement = Items.Find("FormPeriodEndClosingDates");
	If SettingBanDatesElement <> Undefined Then
		SettingBanDatesElement.Visible = ThereAreBanDates;
	EndIf;
	
	If RegistrationPeriod > SettlementStartDate Then
		Items.PeriodEndClosingRecalculationIsRequiredFrom.Title = NStr("vi = 'Cần tính toán lại từ';
																		|ru = 'Требуется пересчет с';
																		|en = 'Recalculation is required from'; fa = 'محاسبه مجدد الزامی است از';
																		|it = 'Требуется пересчет с';
																		|pl = 'Recalculation is required from';
																		|tr = 'Şundan itibaren yeniden hesaplama gerekiyor'");
	Else
		Items.PeriodEndClosingRecalculationIsRequiredFrom.Title = NStr("vi = 'Cần tính lại cho';
																		|ru = 'Требуется пересчет за';
																		|en = 'Recalculation is required for'; fa = 'Recalculation is required for';
																		|it = 'Требуется пересчет за';
																		|pl = 'Recalculation is required for';
																		|tr = 'Şu dönem için yeniden hesaplama gerekiyor'");
	EndIf;
	
	// Let's set the form header.
	PeriodPresentation =
		CostCalculationProtocol.PresentationOfCalculationPeriod(SettlementStartDate)
		+ ?(RegistrationPeriod > SettlementStartDate,
				" - " + CostCalculationProtocol.PresentationOfCalculationPeriod(RegistrationPeriod),
				"");
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tính toán cho giai đoạn %1 là không thể';
			|ru = 'Расчет за период %1 невозможен';
			|en = 'Cannot calculate for the period of %1'; fa = 'Cannot calculate for the period of %1';
			|it = 'Il calcolo per il periodo %1 non è possibile';
			|pl = 'Rozliczenie za okres %1 jest niemożliwe';
			|tr = '%1 dönemi için hesaplama yapılamıyor'", Common.DefaultLanguageCode()),
		PeriodPresentation);
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure SetUpLockFromChanges(Command)
	
	CloseHandler = New CallbackDescription("ClosingBlockingSettingsForm", ThisObject);
	
	OpenForm(
		"InformationRegister.SetUpLockFromChanges.Form.FormSettings",
		,
		ThisObject,
		UUID,
		,
		,
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ViewTaskPeriods(Command)

	TabDoc = TabularDocumentOfTasks();
	TabDoc.Show(NStr("vi = 'Kỳ nhiệm vụ cần tính toán giao dịch đóng tháng';
					|ru = 'Периоды заданий к расчету операций закрытия месяца';
					|en = 'Job periods to calculate month-end closing operations'; fa = 'Job periods to calculate month-end closing operations';
					|it = 'Периоды заданий к расчету операций закрытия месяца';
					|pl = 'Job periods to calculate month-end closing operations';
					|tr = 'Ay sonu kapanış hesaplamak için görev dönemleri'"));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPeriodEndClosing

&AtClient
Procedure PeriodEndClosingSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.PeriodEndClosing.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(, CurrentData.Organization);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// The ban is not set.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEndClosingFirstPermittedPeriod.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.FirstPermittedPeriod");
	ItemFilter.RightValue = Date(1,1,1);
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Không cấm';
															|ru = 'Без запрета';
															|en = 'No period-end closing'; fa = 'No period-end closing';
															|it = 'Nessun divieto';
															|pl = 'Bez zakazu';
															|tr = 'Yasak olmadan'", Common.DefaultLanguageCode()));
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Green);
	
	// The period is forbidden to change.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEndClosingFirstPermittedPeriod.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEndClosingOrganization.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.FirstPermittedPeriod");
	ItemFilter.RightValue = New DataCompositionField("SettlementStartDate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Greater;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	// The lock is not set.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEndClosingFirstUnblockedPeriod.Name);
	
	FilterGroup = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.FirstUnblockedPeriod");
	ItemFilter.RightValue = Date(1,1,1);
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.LockError");
	ItemFilter.RightValue = False;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa phong tỏa';
															|ru = 'Не заблокированы';
															|en = 'Not locked'; fa = 'Not locked';
															|it = 'Не заблокированы';
															|pl = 'Not locked';
															|tr = 'Kilitli değil'", Common.DefaultLanguageCode()));
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Green);
	
	// The block is incorrect.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEndClosingFirstUnblockedPeriod.Name);
	
	FilterGroup = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.FirstUnblockedPeriod");
	ItemFilter.RightValue = Date(1,1,1);
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.LockError");
	ItemFilter.RightValue = True;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Đã phong tỏa sai';
															|ru = 'Заблокированы некорректно';
															|en = 'Locked incorrectly'; fa = 'Locked incorrectly';
															|it = 'Заблокированы некорректно';
															|pl = 'Locked incorrectly';
															|tr = 'Hatalı kilitlenmiş'", Common.DefaultLanguageCode()));
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	// Blocking some organizations.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEndClosingFirstUnblockedPeriod.Name);
	
	FilterGroup = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.FirstUnblockedPeriod");
	ItemFilter.RightValue = Date(1,1,1);
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.LockError");
	ItemFilter.RightValue = True;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	// The block is correct.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEndClosingFirstUnblockedPeriod.Name);
	
	FilterGroup = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.FirstUnblockedPeriod");
	ItemFilter.RightValue = Date(1,1,1);
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.LockError");
	ItemFilter.RightValue = False;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Green);
	
	// The accounting policy is not set.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEndClosingAccountingPolicy.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.AccountingPolicy");
	ItemFilter.RightValue = Date(1,1,1);
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa tùy chỉnh tất cả phân hệ trong chính sách kế toán';
															|ru = 'Не настроены все разделы учетной политики';
															|en = 'All sections of the accounting policy are not configured'; fa = 'All sections of the accounting policy are not configured';
															|it = 'All sections of the accounting policy are not configured';
															|pl = 'All sections of the accounting policy are not configured';
															|tr = 'Muhasebe politikasının tüm bölümleri ayarlanmadı'", Common.DefaultLanguageCode()));
	
	// There are no accounting policies in the calculated period.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEndClosingAccountingPolicy.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEndClosingOrganization.Name);
	
	FilterGroup = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.AccountingPolicy");
	ItemFilter.RightValue = Date(1,1,1);
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	FilterGroup2 = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.AccountingPolicy");
	ItemFilter.RightValue = New DataCompositionField("SettlementStartDate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Greater;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.ThereAreRegisteredRecords");
	ItemFilter.RightValue = True;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	// There are accounting policies in the calculated period.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PeriodEndClosingAccountingPolicy.Name);
	
	FilterGroup = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.AccountingPolicy");
	ItemFilter.RightValue = New DataCompositionField("SettlementStartDate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.LessOrEqual;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PeriodEndClosing.AccountingPolicy");
	ItemFilter.RightValue = Date(1,1,1);
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Green);
	
EndProcedure

&AtClient
Procedure ClosingBlockingSettingsForm(ClosingResult, AdditionalParameters) Export
	
	ForcedToUpdateForm = TypeOf(ClosingResult) = Type("Structure") 
		And CommonClientServer.HasAttributeOrObjectProperty(ClosingResult, "UpdateCloseMonthForm");
	
	If Not ForcedToUpdateForm Then
		Return;
	EndIf;
	
EndProcedure

&AtServer
Function TabularDocumentOfTasks()
	
	DecryptionOfTasks = DecryptionOfTasks; // ValueStorage
	
	Return CostCalculationUniversalAlgorithms.TableOfValuesInTabularDocument(DecryptionOfTasks.Get());
	
EndFunction

#EndRegion
