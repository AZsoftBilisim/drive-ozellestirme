#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//	ValueTableRow, Undefined - the generated command to output to the submenu.
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.LimitsByBudgetingData)
		And LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.LimitsByBudgetingData.FullName();
		ReportCommand.Presentation = NStr("vi = 'Hạn mức theo dữ liệu lập ngân sách';
											|ru = 'Лимиты по данным бюджетирования';
											|en = 'Budgeting limits'; fa = 'سقف‌های بودجه‌بندی';
											|it = 'Лимиты по данным бюджетирования';
											|pl = 'Budgeting limits';
											|tr = 'Bütçeleme verileri kapsamındaki limitler'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "UsingLimitsBasedOnBudgetingDataContext";
		
		Return ReportCommand;
	
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndRegion

#Region Internal

Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings,
		"UsingLimitsBasedOnBudgetingData");
	OptionSettings.LongDesc =
		NStr("vi = 'Phân tích hạn mức thực tế so với kế hoạch theo dữ liệu lập ngân sách';
			|ru = 'План-факт анализ лимитов по данным бюджетирования';
			|en = 'Variance analysis of budgeting limits'; fa = 'Variance analysis of budgeting limits';
			|it = 'План-факт анализ лимитов по данным бюджетирования';
			|pl = 'Variance analysis of budgeting limits';
			|tr = 'Bütçeleme verilerine dayalı limitlerin plan-olgu analizi'");
	
EndProcedure

Function PresentationOfReportAnalyticsWithShift(AnalyticsPresentation, GroupingLevel) Export
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1%2';
			|ru = '%1%2';
			|en = '%1%2'; fa = '%1%2';
			|it = '%1%2';
			|pl = '%1%2';
			|tr = '%1%2'"),
		ShiftingReportDimensions(GroupingLevel),
		AnalyticsPresentation);
EndFunction

#EndRegion

#Region Private

// Returns a string of empty characters for the grouping level shift.
// The length of the shift depends on the level of grouping.
//
// Parameters:
// 	GroupingLevel - Number - The grouping level of the report.
//
// Returns:
// 	String - A string of empty characters before the representation of the grouping value.
//
Function ShiftingReportDimensions(GroupingLevel)
	Return StringFunctionsClientServer.GenerateCharacterString("  ", GroupingLevel);
EndFunction

Procedure DisplayRelevanceOfReflectingReservesByLimits(ResultDocument, AuxProperties,
	CheckActiveTasks = True) Export
	
	NeedInscription = AuxProperties.Property("NumberOfDocumentsToReflectLimitsBasedOnBudgetingData");
	
	If CheckActiveTasks Then
		Var_Key = StrTemplate("ThreadOfControl_%1", "JobsOfRecordingLimitsByBudgetingData");
		
		Filter = New Structure();
		Filter.Insert("Key", Var_Key);
		Filter.Insert("State", BackgroundJobState.Active);
		
		ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
		
		If ActiveTasks.Count() = 0 Then
			NeedInscription = False;
		EndIf;
	EndIf;
	
	If NeedInscription Then
		WarningTable_ = New SpreadsheetDocument;
		AreaWarning = WarningTable_.Area(1,1,1,1);
		PieceOfText = New Array;
		PieceOfText.Add(NStr("vi = 'Việc ghi hạn mức theo dữ liệu lập ngân sách đợi %1 chứng từ.';
							|ru = 'Отражения лимитов по данным бюджетирования ожидает %1 документов.';
							|en = '%1 documents await recording budgeting limits.'; fa = '%1 documents await recording budgeting limits.';
							|it = 'Отражения лимитов по данным бюджетирования ожидает %1 документов.';
							|pl = '%1 documents await recording budgeting limits.';
							|tr = 'Bütçeleme verilerine ilişkin limitlerin yansıtılması %1 belgelerini beklemektedir.'"));
		PieceOfText.Add(NStr("vi = 'Đã khởi động nhiệm vụ theo việc ghi hạn mức.';
							|ru = 'Запущено задание по отражению лимитов.';
							|en = 'The limit recording job is started.'; fa = 'The limit recording job is started.';
							|it = 'Запущено задание по отражению лимитов.';
							|pl = 'The limit recording job is started.';
							|tr = 'Limitleri yansıtma görevi başlatıldı.'"));
		PieceOfText.Add(NStr("vi = 'Bạn sẽ được đề nghị tạo lại báo cáo sau khi ghi.';
							|ru = 'После отражения Вам будет предложено переформировать отчет.';
							|en = 'You will be offered to rebuild the report after recording.'; fa = 'You will be offered to rebuild the report after recording.';
							|it = 'Dopo la riflessione, Vi sarà proposto di creare nuovamente il report.';
							|pl = 'Po odbiciu zostanie wyświetlony monit o ponownym formowaniu raportu.';
							|tr = 'Yansıtıldıktan sonra raporun tekrar oluşturmanızı öneririz.'"));
		WarningText = StrConcat(PieceOfText, Chars.LF);
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			WarningText,
			AuxProperties.NumberOfDocumentsToReflectLimitsBasedOnBudgetingData);
		AreaWarning.Text = WarningText;
		AreaWarning.TextColor = StyleColors.NegativeTextColor;
		ResultDocument.InsertArea(WarningTable_.Area(1, , 1, ), ResultDocument.Area(1, , 1, ),
			SpreadsheetDocumentShiftType.Vertical);
	Else
		AuxProperties.Delete("NumberOfDocumentsToReflectLimitsBasedOnBudgetingData");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf