#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var MCodeUpdateMode Export; // if the flag is set, the name, 
// duration representation, and schedule representation are not updated 
Var MNameUpdateMode Export; // if the flag is set, we do not perform checks
Var MPeriodicityOfParent Export;

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	Var Errors;
	
	If MCodeUpdateMode Then
		CheckedAttributes.Clear();
		Return;
	EndIf;
	
	VerifiedObjectAttributes = New Array;
	If IsFolder Then
		VerifiedObjectAttributes.Add("Description");
		VerifiedObjectAttributes.Add("LongDesc");
		If StartCondition = Enums.TypesOfBudgetingStepStartConditions.Manually Then
			VerifiedObjectAttributes.Add("TypePeriod");
			VerifiedObjectAttributes.Add("Periodicity");
		EndIf;
	Else
		CheckedAttributes.Add("Parent");
	EndIf;
	
	If Not IsFolder Then
		If Not ExecuteAutomatically Then
			CheckedAttributes.Add("EmployeeResponsible");
		EndIf;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, VerifiedObjectAttributes);
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	Var Errors, PeriodicityOfParent;
	
	If DataExchange.Load Or MCodeUpdateMode Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsFolder Then
		If MNameUpdateMode Then
			PeriodicityOfParent = MPeriodicityOfParent;
		Else
			PeriodicityOfParent = ?(ValueIsFilled(Parent), Common.ObjectAttributeValue(Parent,
				"Periodicity"), Common.ObjectAttributeValue(Owner, "Periodicity"));
		EndIf;
		
		PeriodicityRepresentation = "";
		
		If Periodicity = PeriodicityOfParent Then
			PeriodicityRepresentation = NStr("vi = 'Một lần';
											|ru = 'Однократно';
											|en = 'Once'; fa = 'یک‌بار';
											|it = 'Una volta';
											|pl = 'Jednorazowo';
											|tr = 'Tek seferlik'");
		ElsIf Periodicity = Enums.Periodicity.Day Then
			PeriodicityRepresentation = NStr("vi = 'Hàng ngày';
											|ru = 'Ежедневно';
											|en = 'Daily'; fa = 'روزانه';
											|it = 'Ogni giorno';
											|pl = 'Codziennie';
											|tr = 'Günlük'");
		ElsIf Periodicity = Enums.Periodicity.Week Then
			PeriodicityRepresentation = NStr("vi = 'Hàng tuần';
											|ru = 'Еженедельно';
											|en = 'Weekly'; fa = 'هفتگی';
											|it = 'Ogni settimana';
											|pl = 'Co tydzień';
											|tr = 'Haftalık'");
		ElsIf Periodicity = Enums.Periodicity.TenDays Then
			PeriodicityRepresentation = NStr("vi = 'Theo 10 ngày';
											|ru = 'По декадам';
											|en = 'By ten-day periods'; fa = 'بر اساس دوره‌های ده‌روزه';
											|it = 'Per decenni';
											|pl = 'Według dekad';
											|tr = 'On günlük süreye göre'");
		ElsIf Periodicity = Enums.Periodicity.Month Then
			PeriodicityRepresentation = NStr("vi = 'Hàng tháng';
											|ru = 'Ежемесячно';
											|en = 'Monthly'; fa = 'ماهانه';
											|it = 'Mensilmente';
											|pl = 'Co miesiąc';
											|tr = 'Aylık'");
		ElsIf Periodicity = Enums.Periodicity.Quarter Then
			PeriodicityRepresentation = NStr("vi = 'Hàng quý';
											|ru = 'Ежеквартально';
											|en = 'Quarterly'; fa = 'فصلی';
											|it = 'Trimestralmente';
											|pl = 'Co kwartał';
											|tr = 'Üç ayda bir'");
		ElsIf Periodicity = Enums.Periodicity.HalfYear Then
			PeriodicityRepresentation = NStr("vi = 'Theo nửa năm';
											|ru = 'По полугодиям';
											|en = 'By half-year periods'; fa = 'بر اساس دوره‌های نیم‌ساله';
											|it = 'Per sei  mesi';
											|pl = 'Według półroczy';
											|tr = 'Yarıyıllara göre'");
		ElsIf Periodicity = Enums.Periodicity.Year Then
			PeriodicityRepresentation = NStr("vi = 'Hàng năm';
											|ru = 'Ежегодно';
											|en = 'Annually'; fa = 'سالانه';
											|it = 'Annualmente';
											|pl = 'Co roku';
											|tr = 'Yıllık'");
		EndIf;
		If IsBlankString(LongDesc) Then
			Description = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1, %2';
					|ru = '%1, %2';
					|en = '%1, %2'; fa = '%1, %2';
					|it = '%1, %2';
					|pl = '%1, %2';
					|tr = '%1, %2'"),
				PeriodicityRepresentation,
				StageExecutionProcedure);
		Else
			Description = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 (%2, %3)';
					|ru = '%1 (%2, %3)';
					|en = '%1 (%2, %3)'; fa = '%1 (%2, %3)';
					|it = '%1 (%2, %3)';
					|pl = '%1 (%2, %3)';
					|tr = '%1 (%2, %3)'"),
				String(LongDesc),
				PeriodicityRepresentation,
				StageExecutionProcedure);
		EndIf;
		
		FillSchedulePresentation();
		
		If MNameUpdateMode Then
			Return;
		EndIf;
	Else
		If DurationType = Enums.TypesOfBudgetingStepDurations.CalendarDays Then
			DurationDescription = NStr("vi = ';%1 ngày dương lịch;;%1 ngày dương lịch;%1 ngày dương lịch;';
										|ru = ';%1 календарный день;;%1 календарных дня;%1 календарных дней;';
										|en = ';%1 calendar day;;%1 calendar days;%1 calendar days;'; fa = ';%1 calendar day;;%1 calendar days;%1 calendar days;';
										|it = ';%1 giorno di calendario;;%1 giorni di calendario;%1 giorni di calendario;';
										|pl = ';%1 dzień kalendarzowy;;%1 dni kalendarzowych;%1 dni kalendarzowych;';
										|tr = ';%1 takvim günü;;%1 takvim günleri;%1 takvim günleri;'");
		Else
			DurationDescription = NStr("vi = ';%1 ngày làm việc;;%1 ngày làm việc;%1 ngày làm việc;';
										|ru = ';%1 рабочий день;;%1 рабочих дня;%1 рабочих дней;';
										|en = ';%1 workday;;%1 workdays;%1 workdays;'; fa = ';%1 workday;;%1 workdays;%1 workdays;';
										|it = ';%1 giorno di lavoro;;%1 giorni di lavoro;%1 giorni di lavoro;';
										|pl = ';%1 roboczy dzień;;%1 roboczych dni;%1 roboczych dni;';
										|tr = ';%1 iş günü;;%1 iş günleri;%1 iş günleri;'");
		EndIf;
		DurationPresentation = StringFunctionsClientServer.StringWithNumberForAnyLanguage(DurationDescription, Duration);
		SettingUpTableAction = SettingOfAction.Get();
		If TypeOf(SettingUpTableAction) = Type("ValueTable") Then
			ActionSettingPresentation = Enums.TypesOfBudgetingStepActions.GetActionPresentation(
				SettingUpTableAction, Action);
		EndIf;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("Ref", Ref);
	
	Query.Text = "SELECT
	|	BudgetingSteps.Parent,
	|	BudgetingSteps.Periodicity
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Ref = &Ref";
	
	Selection = Query.Execute().Select();
	
	PreviousParent_ = Catalogs.BudgetingSteps.EmptyRef();
	PreviousPeriodicity = Periodicity;
	If Selection.Next() Then
		PreviousParent_ = Selection.Parent;
		PreviousPeriodicity = Selection.Periodicity;
	EndIf;
	
	If IsFolder Then
		If Not Ref.IsEmpty() Then
			CheckPossibilityOfChangingPeriodicity(Errors, PreviousPeriodicity);
		EndIf;
		
		CheckPeriodicityByParent(Errors, PeriodicityOfParent);
		CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	EndIf;
	
	If Not Ref.IsEmpty() And Not Cancel Then
		
		If Parent <> PreviousParent_ Then
			SetNewCode();
			Catalogs.BudgetingSteps.RenumberGroupOfElements(PreviousParent_, Ref);
		EndIf;
		
		If IsFolder Then
			If Periodicity <> PreviousPeriodicity Then
				
				Query.Text = 
				"SELECT
				|	BudgetingSteps.Ref
				|FROM
				|	Catalog.BudgetingSteps AS BudgetingSteps
				|WHERE
				|	BudgetingSteps.IsFolder
				|	AND BudgetingSteps.Parent = &Ref";
				
				QueryResult = Query.Execute();
				SelectionDetailRecords = QueryResult.Select();
				
				While SelectionDetailRecords.Next() Do
					Object = SelectionDetailRecords.Ref.GetObject(); // CatalogObject.BudgetingSteps -
					Object.MNameUpdateMode = True;
					Object.MPeriodicityOfParent = Periodicity;
					Object.Write();
				EndDo;
				
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// The procedure fills in the "Schedule View" Attribute based on the selected startup parameters to be displayed in the list.
//
Procedure FillSchedulePresentation()
	
	If DueDate > 0 Then
		If TypePeriod = Enums.TypesOfBudgetingStepDurations.CalendarDays Then
			PeriodTemplate = NStr("vi = ';%1 ngày dương lịch;;%1 ngày dương lịch;%1 ngày dương lịch;';
									|ru = ';%1 календарный день;;%1 календарных дня;%1 календарных дней;';
									|en = ';%1 calendar day;;%1 calendar days;%1 calendar days;'; fa = ';%1 calendar day;;%1 calendar days;%1 calendar days;';
									|it = ';%1 giorno di calendario;;%1 giorni di calendario;%1 giorni di calendario;';
									|pl = ';%1 dzień kalendarzowy;;%1 dni kalendarzowych;%1 dni kalendarzowych;';
									|tr = ';%1 takvim günü;;%1 takvim günleri;%1 takvim günleri;'");
		Else
			PeriodTemplate = NStr("vi = ';%1 ngày làm việc;;%1 ngày làm việc;%1 ngày làm việc;';
									|ru = ';%1 рабочий день;;%1 рабочих дня;%1 рабочих дней;';
									|en = ';%1 workday;;%1 workdays;%1 workdays;'; fa = ';%1 workday;;%1 workdays;%1 workdays;';
									|it = ';%1 giorno di lavoro;;%1 giorni di lavoro;%1 giorni di lavoro;';
									|pl = ';%1 roboczy dzień;;%1 roboczych dni;%1 roboczych dni;';
									|tr = ';%1 iş günü;;%1 iş günleri;%1 iş günleri;'");
		EndIf;
		TermPresentation = StringFunctionsClientServer.StringWithNumberForAnyLanguage(PeriodTemplate, DueDate);
		
		If StartCondition = Enums.TypesOfBudgetingStepStartConditions.BeforePeriodEnd Then
			SchedulePresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Bắt đầu trước khi kết thúc giai đoạn cho%1';
					|ru = 'Начать до окончания периода за %1';
					|en = 'Start before the end of the period %1'; fa = 'Start before the end of the period %1';
					|it = 'Cominciare prima della fine del periodo per %1';
					|pl = 'Rozpocząć przed końcem okresu za %1';
					|tr = '%1 için dönemin bitişine kadar başlat'"),
				TermPresentation);
		ElsIf StartCondition = Enums.TypesOfBudgetingStepStartConditions.BeforePeriodStart Then
			SchedulePresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Bắt đầu trước khi bắt đầu giai đoạn cho%1';
					|ru = 'Начать до начала периода за %1';
					|en = 'Start  %1 prior to the period start'; fa = 'Start  %1 prior to the period start';
					|it = 'Cominciare prima dell''inizio del periodo per %1';
					|pl = 'Rozpocząć przed początkiem okresu za %1';
					|tr = '%1 için dönemin başlangıcına kadar başlat'"),
				TermPresentation);
		ElsIf StartCondition = Enums.TypesOfBudgetingStepStartConditions.AfterPeriodEnd Then
			SchedulePresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Bắt đầu sau khi kết thúc giai đoạn tính theo%1';
					|ru = 'Начать после окончания периода через %1';
					|en = 'Start after the end of the period in %1'; fa = 'Start after the end of the period in %1';
					|it = 'Cominciare dopo la fine del periodo fra%1';
					|pl = 'Rozpocząć po zakończeniu okresu przez %1';
					|tr = '%1 itibarıyla sonlanma döneminden sonra başlat'"),
				TermPresentation);
		Else
			SchedulePresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Bắt đầu sau khi bắt đầu giai đoạn tính theo%1%2';
					|ru = 'Начать после начала периода через %1 %2';
					|en = 'Start before the start of the period in %1%2'; fa = 'Start before the start of the period in %1%2';
					|it = 'Cominciare dopo la fine del periodo fra%1%2';
					|pl = 'Rozpocząć po rozpoczęciu okresu przez %1 %2';
					|tr = '%1 %2 itibarıyla başlangıç döneminden sonra başlat'"),
				DueDate,
				Lower(TypePeriod));
		EndIf;
	Else
		If StartCondition = Enums.TypesOfBudgetingStepStartConditions.Manually Then
			SchedulePresentation = NStr("vi = 'Bắt đầu thủ công';
										|ru = 'Начать вручную';
										|en = 'Start manually'; fa = 'Start manually';
										|it = 'Начать вручную';
										|pl = 'Start manually';
										|tr = 'Manuel olarak başlat'");
		ElsIf StartCondition = Enums.TypesOfBudgetingStepStartConditions.BeforePeriodEnd
			Or StartCondition = Enums.TypesOfBudgetingStepStartConditions.BeforePeriodStart Then
			SchedulePresentation = NStr("vi = 'Bắt đầu từ đầu kỳ';
										|ru = 'Начать вместе с началом периода';
										|en = 'Start when the period starts'; fa = 'Start when the period starts';
										|it = 'Cominciare insieme all''inizio del periodo';
										|pl = 'Rozpocząć wraz z początkiem okresu';
										|tr = 'Başlangıç dönemiyle birlikte başlat'");
		Else
			SchedulePresentation = NStr("vi = 'Bắt đầu với cuối kỳ';
										|ru = 'Начать вместе с  окончанием периода';
										|en = 'Start when the period ends'; fa = 'Start when the period ends';
										|it = 'Cominciare insieme alla fine del periodo';
										|pl = 'Rozpocząć wraz z zakończeniem okresu';
										|tr = 'Bitiş dönemiyle birlikte başlat'");
		EndIf;
	EndIf;
	
EndProcedure

Procedure CheckPossibilityOfChangingPeriodicity(Errors, PreviousPeriodicity)
	
	If Periodicity = PreviousPeriodicity Then
		Return;
	EndIf;
	
	TableOfPeriodicities = Enums.Periodicity.OrderedPeriodicities(True);
	
	Query = New Query();
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Periodicity", Periodicity);
	Query.SetParameter("TableOfPeriodicities", TableOfPeriodicities);
	
	Query.Text =
	"SELECT
	|	TableOfPeriodicities.Periodicity,
	|	TableOfPeriodicities.Order
	|INTO OrderedPeriodicities
	|FROM
	|	&TableOfPeriodicities AS TableOfPeriodicities
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderedPeriodicities.Periodicity,
	|	OrderedPeriodicities.Order
	|INTO PeriodicityCur
	|FROM
	|	OrderedPeriodicities AS OrderedPeriodicities
	|		INNER JOIN Enum.Periodicity AS EnumPeriodicity
	|		ON OrderedPeriodicities.Periodicity = EnumPeriodicity.Ref
	|			AND (EnumPeriodicity.Ref = &Periodicity)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MAX(OrderedPeriodicities.Order), 0) AS SubordinateOrder,
	|	FrequencyOfLaunchingBudgetProcessTask.Order
	|INTO TempTable
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|		INNER JOIN OrderedPeriodicities AS OrderedPeriodicities
	|		ON (OrderedPeriodicities.Periodicity = BudgetingSteps.Periodicity)
	|		INNER JOIN PeriodicityCur AS FrequencyOfLaunchingBudgetProcessTask
	|		ON (TRUE)
	|WHERE
	|	BudgetingSteps.Ref IN HIERARCHY(&Ref)
	|	AND BudgetingSteps.IsFolder
	|	AND BudgetingSteps.Ref <> &Ref
	|
	|GROUP BY
	|	FrequencyOfLaunchingBudgetProcessTask.Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	1 AS Field1
	|FROM
	|	TempTable AS TempTable
	|WHERE
	|	TempTable.Order < TempTable.SubordinateOrder";
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		CommonClientServer.AddUserError(Errors,
		"Periodicity",
		NStr("vi = 'Không thể thay đổi tần số. Đầu tiên, thay đổi tần số của các nhóm nhỏ';
			|ru = 'Невозможно изменить периодичность. Сначала измените периодичность у подчиненных групп';
			|en = 'Cannot change frequency. First, change frequency of the subordinate groups'; fa = 'Cannot change frequency. First, change frequency of the subordinate groups';
			|it = 'Non è possibile modificare l''intervallo di tempo. Modificare l''intervallo di tempo prima ai gruppi subordinati';
			|pl = 'Zmiana okresowości nie jest możliwa. Najpierw zmień okresowość grup podporządkowanych';
			|tr = 'Sıklık değiştirilemez. Öncelikle alt grupların sıklıklarını değiştiriniz'"), "");
	EndIf;
	
	Query.Text = "SELECT TOP 1
	|	BudgetTask.Ref
	|FROM
	|	Task.BudgetTask AS BudgetTask
	|WHERE
	|	BudgetTask.BudgetingStep IN HIERARCHY(&BudgetingStep)";
	
	Query.SetParameter("BudgetingStep", Ref);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		CommonClientServer.AddUserError(Errors,
		"Periodicity",
		NStr("vi = 'Không thể thay đổi định kỳ.
			|Có nhiệm vụ đã tạo theo các giai đoạn trực thuộc. 
			|Hãy đặt dấu hộp kiểm ""Chưa thực hiện"" trong giai đoạn và tạo mới giai đoạn.';
			|ru = 'Невозможно изменить периодичность.
			|Есть созданные задачи по подчиненным этапам. 
			|Установите флаг ""Не выполняется"" у этапа и создайте новый этап.';
			|en = 'Cannot change frequency.
			|There are created tasks for the subordinate steps.
			|Select the ""Not executed"" check box for the step and create a new step.'; fa = 'Cannot change frequency.
			|There are created tasks for the subordinate steps.
			|Select the ""Not executed"" check box for the step and create a new step.';
			|it = 'Non è possibile modificare l''intervallo di tempo.
			| Vi sono task creati per le fasi subordinate. 
			| Impostate la flag ""non eseguire"" presso tale fase e creare una nuova fase.';
			|pl = 'Zmiana okresowości nie jest możliwa.
			|Istnieją utworzone zadania w etapach podporządkowanych. 
			|Zaznacz dla etapu pole wyboru ""Nie jest wykonywany"" i utwórz nowy etap.';
			|tr = 'Sıklık değiştirilemez.
			|Alt aşamalara göre oluşturulmuş görevler mevcut. 
			|Aşamadaki ""Doldurulmamış"" işaretini ayarlayın ve yeni bir aşama oluşturun.'"), "");
		
	EndIf;
	
EndProcedure

Procedure CheckPeriodicityByParent(Errors, PeriodicityOfParent)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfPeriodicities.Periodicity,
	|	TableOfPeriodicities.Order
	|INTO OrderedPeriodicities
	|FROM
	|	&TableOfPeriodicities AS TableOfPeriodicities
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderedPeriodicities.Order
	|INTO PeriodicityParent
	|FROM
	|	OrderedPeriodicities AS OrderedPeriodicities
	|		INNER JOIN Enum.Periodicity AS EnumPeriodicity
	|		ON OrderedPeriodicities.Periodicity = EnumPeriodicity.Ref
	|			AND (EnumPeriodicity.Ref = &PeriodicityOfParent)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderedPeriodicities.Order
	|INTO Periodicity
	|FROM
	|	OrderedPeriodicities AS OrderedPeriodicities
	|		INNER JOIN Enum.Periodicity AS EnumPeriodicity
	|		ON OrderedPeriodicities.Periodicity = EnumPeriodicity.Ref
	|			AND (EnumPeriodicity.Ref = &Periodicity)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(NestedQuery.ParentOrder) AS ParentOrder,
	|	MAX(NestedQuery.Order) AS Order
	|FROM
	|	(SELECT
	|		PeriodicityParent.Order AS ParentOrder,
	|		NULL AS Order
	|	FROM
	|		PeriodicityParent AS PeriodicityParent
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NULL,
	|		Periodicity.Order
	|	FROM
	|		Periodicity AS Periodicity) AS NestedQuery";
	
	TableOfPeriodicities = Enums.Periodicity.OrderedPeriodicities(True);
	Query.SetParameter("TableOfPeriodicities", TableOfPeriodicities);
	Query.SetParameter("Periodicity", Periodicity);
	Query.SetParameter("PeriodicityOfParent", PeriodicityOfParent);
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Order > Selection.ParentOrder Then
		CommonClientServer.AddUserError(Errors,
			"Periodicity",
			NStr("vi = 'Tần số phải nhỏ hơn tần số của nhóm';
				|ru = 'Периодичность должна быть меньше периодичности группы';
				|en = 'Frequency should be less than the group frequency'; fa = 'Frequency should be less than the group frequency';
				|it = 'L''intervallo di tempo dovrà essere inferiore a quello del gruppo';
				|pl = 'Okresowość musi być mniejsza od okresowości grupy';
				|tr = 'Sıklık, sıklık grubundan daha az olmalıdır'"),
			"");
	EndIf;
	
EndProcedure

MCodeUpdateMode = False;
MNameUpdateMode = False;

#EndRegion

#EndIf
