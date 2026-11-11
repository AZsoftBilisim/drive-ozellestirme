
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Scenario = Parameters.Scenario;
	PlanningType = Parameters.PlanningType;
	If PlanningType = "AssemblyProductionPlanning"
		Or PlanningType = "DisassemblyProductionPlanning"Then
		DateOfReceipt = Parameters.ProductionDate;
	ElsIf PlanningType = "PurchasePlanning" Then
		DateOfReceipt = Parameters.DateOfReceipt;
	ElsIf PlanningType = "PlanningAssemblyDisassembly" Then
		DateOfReceipt = Parameters.AssemblyPeriodStart;
	ElsIf PlanningType = "PlanningTransferOfMaterialsToProduction" Then
		DateOfReceipt = Parameters.DemandPeriodStart;
	EndIf;
	
	If PlanningType = "AssemblyProductionPlanning" Then
		Items.Periodicity.Title = NStr("vi = 'Định kỳ kế hoạch sản xuất';
										|ru = 'Периодичность планов производства';
										|en = 'Production plan frequency'; fa = 'Production plan frequency';
										|it = 'Periodicità dei piani di produzione';
										|pl = 'Częstotliwość planów produkcji';
										|tr = 'Üretim planı sıklığı'");
		Items.Operation.ChoiceList[0].Presentation = NStr("vi = 'Chuyển ngày xuất xưởng';
															|ru = 'Перенести дату выпуска';
															|en = 'Change release date'; fa = 'Change release date';
															|it = 'Spostare la data di rilascio';
															|pl = 'Przenieś datę wypuszczenia';
															|tr = 'Üretim tarihini taşı'");
		Items.DistributionGroup_5.Title = NStr("vi = 'Phân bổ ngày phát hành';
												|ru = 'Распределить даты выпуска';
												|en = 'Allocate release dates'; fa = 'Allocate release dates';
												|it = 'Ridistribuire le date di rilascio';
												|pl = 'Przydzielaj daty wypuszczenia';
												|tr = 'Üretim tarihlerini dağıt'");
		Items.DayOfTheWeekDistribution.Title = NStr("vi = 'Phát hành trong';
													|ru = 'Выпуск в';
													|en = 'Release in'; fa = 'Release in';
													|it = 'Rilascio il';
													|pl = 'Wyprodukowanie w';
													|tr = 'Üretim'");
	ElsIf PlanningType = "DisassemblyProductionPlanning" Then
		Items.Periodicity.Title = NStr("vi = 'Định kỳ kế hoạch sản xuất';
										|ru = 'Периодичность планов производства';
										|en = 'Production plan frequency'; fa = 'Production plan frequency';
										|it = 'Periodicità dei piani di produzione';
										|pl = 'Częstotliwość planów produkcji';
										|tr = 'Üretim planı sıklığı'");
		Items.Operation.ChoiceList[0].Presentation = NStr("vi = 'Chuyển ngày khởi động';
															|ru = 'Перенести дату запуска';
															|en = 'Change start date'; fa = 'Change start date';
															|it = 'Spostare la data di avvio';
															|pl = 'Przenieś datę uruchomienia';
															|tr = 'Başlatma tarihini taşı'");
		Items.DistributionGroup_5.Title = NStr("vi = 'Phân bổ ngày phát hành';
												|ru = 'Распределить даты запуска';
												|en = 'Allocate start dates'; fa = 'Allocate start dates';
												|it = 'Ridistribuire le date di avvio';
												|pl = 'Przydzielaj daty uruchomienia';
												|tr = 'Başlatma tarihini dağıt'");
		Items.DayOfTheWeekDistribution.Title = NStr("vi = 'Bắt đầu trong';
													|ru = 'Запуск в';
													|en = 'Start in'; fa = 'Start in';
													|it = 'Avvio il';
													|pl = 'Uruchomienie w';
													|tr = 'Başlatma'");
	ElsIf PlanningType = "PlanningAssemblyDisassembly" Then
		Items.Periodicity.Title = NStr("vi = 'Định kỳ của kế hoạch đóng bộ (tách bộ)';
										|ru = 'Периодичность планов сборки (разборки)';
										|en = 'Kitting plan frequency'; fa = 'Kitting plan frequency';
										|it = 'Periodicità dei piani di assemblaggio (smontaggio)';
										|pl = 'Częstotliwość planów montażu (demontażu)';
										|tr = 'Montaj programının (demontaj) sıklığı'");
		Items.Operation.ChoiceList[0].Presentation = NStr("vi = 'Chuyển ngày bắt đầu đóng bộ (tách bộ)';
															|ru = 'Перенести дату начала сборки (разборки)';
															|en = 'Change kitting start date'; fa = 'Change kitting start date';
															|it = 'Spostare la data di avvio dell''assemblaggio (smontaggio)';
															|pl = 'Przenieś datę początku montażu (demontażu)';
															|tr = 'Montaj (demontaj) başlangıç tarihini taşı'");
		Items.DistributionGroup_5.Title = NStr("vi = 'Phân bổ ngày đóng bộ (tách bộ)';
												|ru = 'Распределить даты сборки (разборки)';
												|en = 'Allocate kitting dates'; fa = 'Allocate kitting dates';
												|it = 'Ridistribuire la data di avvio dell''assemblaggio (smontaggio)';
												|pl = 'Przydziel daty montażu (demontażu)';
												|tr = 'Montaj (demontaj) tarihlerini dağıt'");
		Items.DayOfTheWeekDistribution.Title = NStr("vi = 'Đóng bộ (tách bộ) trong';
													|ru = 'Сборка (разборка) в';
													|en = 'Kitting in'; fa = 'Kitting in';
													|it = 'Assemblaggio (smontaggio) il';
													|pl = 'Montaż (demontaż) w';
													|tr = 'Montaj (demontaj)'");
	ElsIf PlanningType = "PlanningTransferOfMaterialsToProduction" Then
		Items.Periodicity.Title = NStr("vi = 'Định kỳ kế hoạch sản xuất';
										|ru = 'Периодичность планов производства';
										|en = 'Production plan frequency'; fa = 'Production plan frequency';
										|it = 'Periodicità dei piani di produzione';
										|pl = 'Częstotliwość planów produkcji';
										|tr = 'Üretim planı sıklığı'");
		Items.Operation.ChoiceList[0].Presentation = NStr("vi = 'Chuyển ngày vận chuyển vật liệu';
															|ru = 'Перенести дату отгрузки материалов';
															|en = 'Change material shipment date'; fa = 'Change material shipment date';
															|it = 'Spostare la data di scarico dei materiali';
															|pl = 'Przenieś datę wysyłki materiałów';
															|tr = 'Malzeme sevkiyat tarihini taşı'");
		Items.DistributionGroup_5.Title = NStr("vi = 'Phân bổ ngày giao nguyên vật liệu';
												|ru = 'Распределить даты отгрузки материалов';
												|en = 'Allocate material shipment dates'; fa = 'Allocate material shipment dates';
												|it = 'Ridistribuire le date di scarico del materiali';
												|pl = 'Przydziel daty wysyłki materiałów';
												|tr = 'Malzeme sevkiyat tarihlerini dağıt'");
		Items.DayOfTheWeekDistribution.Title = NStr("vi = 'Chuyển giao nguyên vật liệu';
													|ru = 'Передача материалов в';
													|en = 'Transfer materials to'; fa = 'Transfer materials to';
													|it = 'Consegna dei materiali il';
													|pl = 'Przekazanie materiałów w';
													|tr = 'Malzemelerin transferi'");
	EndIf;
	
	Periodicity = Common.ObjectAttributeValue(Scenario, "Periodicity");
	
	If Not ValueIsFilled(DateOfReceipt) Then
	
		DateOfReceipt = CurrentSessionDate();
	
	EndIf;
	
	DateOfReceipt = PlanningClientServer.CalculateStartDateOfPeriod(DateOfReceipt, Periodicity);
	
	Operation = "Transfer";
	
	TransferOption = "ToNumber";
	DayNumber = 1;
	
	AddHalfYearOption = False;
	AddQuarterOption = False;
	AddMonthOption = False;
	AddDecadeOption = False;
	AddOptionOfWeek = False;
	
	If Periodicity = Enums.Periodicity.Year Then
		Items.TransferOption.ChoiceList[0].Presentation = NStr("vi = 'Vào ngày của năm';
																|ru = 'На день года';
																|en = 'On the day of the year'; fa = 'On the day of the year';
																|it = 'Per il giorno dell''anno';
																|pl = 'Na dzień roku';
																|tr = 'Yıl gününde'");
		Items.DayNumber.MaxValue = 365;
		Items.NumberOfPeriods.MaxValue = 365;
		
		AddHalfYearOption = True;
		AddQuarterOption = True;
		AddMonthOption = True;
		AddDecadeOption = True;
		AddOptionOfWeek = True;
		
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		Items.TransferOption.ChoiceList[0].Presentation = NStr("vi = 'Vào ngày của nửa năm';
																|ru = 'На день полугодия';
																|en = 'On the day of the half-year'; fa = 'On the day of the half-year';
																|it = 'Per il giorno del semestre';
																|pl = 'Na dzień półrocza';
																|tr = 'Yarıyıl gününde'");
		Items.DayNumber.MaxValue = 182;
		Items.NumberOfPeriods.MaxValue = 182;
		
		AddQuarterOption = True;
		AddMonthOption = True;
		AddDecadeOption = True;
		AddOptionOfWeek = True;
		
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		Items.TransferOption.ChoiceList[0].Presentation = NStr("vi = 'Vào ngày của quý';
																|ru = 'На день квартала';
																|en = 'On the day of the quarter'; fa = 'On the day of the quarter';
																|it = 'Per il giorno del trimestre';
																|pl = 'Na dzień kwartału';
																|tr = 'Çeyrek gününde'");
		Items.DayNumber.MaxValue = 90;
		Items.NumberOfPeriods.MaxValue = 90;
		
		AddMonthOption = True;
		AddDecadeOption = True;
		AddOptionOfWeek = True;
		
	ElsIf Periodicity = Enums.Periodicity.Month Then
		Items.TransferOption.ChoiceList[0].Presentation = NStr("vi = 'Vào ngày của tháng';
																|ru = 'На число месяца';
																|en = 'On the day of the month'; fa = 'On the day of the month';
																|it = 'Per il giorno del mese';
																|pl = 'Na dzień miesiąca';
																|tr = 'Ayın tarihinde'");
		Items.DayNumber.MaxValue = 31;
		Items.NumberOfPeriods.MaxValue = 31;
		
		AddDecadeOption = True;
		AddOptionOfWeek = True;
		
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		Items.TransferOption.ChoiceList[0].Presentation = NStr("vi = 'Vào ngày trong mười ngày';
																|ru = 'На день в декаде';
																|en = 'On the day in ten-day period'; fa = 'On the day in ten-day period';
																|it = 'Per il giorno nel decennio';
																|pl = 'Na dzień w dekadzie';
																|tr = '10 günlük süre gününde'");
		Items.DayNumber.MaxValue = 10;
		Items.NumberOfPeriods.MaxValue = 10;
	ElsIf Periodicity = Enums.Periodicity.Week Then
		Items.TransferOption.ChoiceList[0].Presentation = NStr("vi = 'Vào ngày trong tuần';
																|ru = 'На день недели';
																|en = 'On the day of the week'; fa = 'On the day of the week';
																|it = 'Per il giorno della settimana';
																|pl = 'Na dzień tygodnia';
																|tr = 'Hafta gününde'");
		Items.DayNumber.MaxValue = 7;
		Items.NumberOfPeriods.MaxValue = 7;
	EndIf; 
	If Periodicity <> Enums.Periodicity.Month Then
		Items.DayNumber.ToolTip = "";
	EndIf;
	
	Items.DateAllocationOption.ChoiceList.Clear();
	Items.GroupDistributionByWeek.Visible = False;
	
	If AddHalfYearOption Then
		Items.DateAllocationOption.ChoiceList.Add("ByHalfYearPeriods", NStr("vi = 'Theo nửa năm';
																			|ru = 'По полугодиям';
																			|en = 'By half-year periods'; fa = 'بر اساس دوره‌های نیم‌ساله';
																			|it = 'Per sei  mesi';
																			|pl = 'Według półroczy';
																			|tr = 'Yarıyıllara göre'"));
	EndIf;
	If AddQuarterOption Then
		Items.DateAllocationOption.ChoiceList.Add("ByQuarters", NStr("vi = 'Theo quý';
																	|ru = 'По кварталам';
																	|en = 'By quarters'; fa = 'By quarters';
																	|it = 'Per trimestri';
																	|pl = 'Według kwartałów';
																	|tr = 'Çeyreklere göre'"));
	EndIf;
	If AddMonthOption Then
		Items.DateAllocationOption.ChoiceList.Add("ByMonths", NStr("vi = 'Theo tháng';
																	|ru = 'По месяцам';
																	|en = 'By months'; fa = 'بر اساس ماه‌ها';
																	|it = 'Per mesi';
																	|pl = 'Według miesięcy';
																	|tr = 'Aylara göre'"));
	EndIf;
	If AddDecadeOption Then
		Items.DateAllocationOption.ChoiceList.Add("ByTenDayPeriods", NStr("vi = 'Theo 10 ngày';
																			|ru = 'По декадам';
																			|en = 'By ten-day periods'; fa = 'بر اساس دوره‌های ده‌روزه';
																			|it = 'Per decenni';
																			|pl = 'Według dekad';
																			|tr = '10 günlük sürelere göre'"));
	EndIf;
	If AddOptionOfWeek Then
		Items.GroupDistributionByWeek.Visible = True;
	EndIf;
	
	Items.DateAllocationOption.Visible = Items.DateAllocationOption.ChoiceList.Count() > 0;
	
	WeekDay = Enums.WeekDays.Monday;
	
	DateAllocationOption = "ByWeeks";
	QuantityAllocationOption = "Proportionally";
	
	SelectToOrder = True;
	CalculateNumberOfDefaultPeriods(NumberOfPeriods, Periodicity, DateAllocationOption, DateOfReceipt, WeekDay);
	
	// Reading the saved previous selection
	DistributionParameters = Common.FormDataSettingsStorageLoad(
		String(Scenario.UUID())+PlanningType,
		"DistributionParameters");
	If TypeOf(DistributionParameters) = Type("Structure") Then
		FillPropertyValues(ThisObject, DistributionParameters,, "Shares");
		CalculateNumberOfDefaultPeriods(NumberOfPeriods, Periodicity, DateAllocationOption, DateOfReceipt, WeekDay);
		
		If DistributionParameters.Property("Shares") And QuantityAllocationOption <> "Proportionally" Then
			
			For Each Share In DistributionParameters.Shares Do
			
				NewRow = Shares.Add();
				NewRow.Share = Share;
			
			EndDo;
			
		EndIf; 
	EndIf;
	
	FillInShares(Shares, NumberOfPeriods, DateAllocationOption);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetAccessibilityVisibility();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OperationOnChange(Item)
	
	SetAccessibilityVisibility();
	
EndProcedure

&AtClient
Procedure TransferOptionOnChange(Item)
	
	SetAccessibilityVisibility();
	
EndProcedure

&AtClient
Procedure DayNumberOnChange(Item)
	
	UpdateTransferHint();
	
EndProcedure

&AtClient
Procedure FirstDayOfTheWeekOnChange(Item)
	
	If Not ValueIsFilled(WeekDay) Then
		WeekDay = PredefinedValue("Enum.WeekDays.Monday");
	EndIf;
	
	UpdateTransferHint();
	
EndProcedure

&AtClient
Procedure LastDayOfTheWeekOnChange(Item)
	
	If Not ValueIsFilled(WeekDay) Then
		WeekDay = PredefinedValue("Enum.WeekDays.Monday");
	EndIf;
	
	UpdateTransferHint();
	
EndProcedure

&AtClient
Procedure DateAllocationOptionOnChange(Item)
	
	CalculateNumberOfDefaultPeriods(NumberOfPeriods, Periodicity, DateAllocationOption, DateOfReceipt, WeekDay);
	
	FillInShares(Shares, NumberOfPeriods, DateAllocationOption);
	
	SetAccessibilityVisibility();
	
EndProcedure

&AtClient
Procedure DayOfTheWeekDistributionOnChange(Item)
	
	If Not ValueIsFilled(WeekDay) Then
		WeekDay = PredefinedValue("Enum.WeekDays.Monday");
	EndIf;
	
	CalculateNumberOfDefaultPeriods(NumberOfPeriods, Periodicity, DateAllocationOption, DateOfReceipt, WeekDay);
	FillInShares(Shares, NumberOfPeriods, DateAllocationOption);
	UpdateDistributionHint();
	
EndProcedure

&AtClient
Procedure NumberOfPeriodsOnChange(Item)
	
	FillInShares(Shares, NumberOfPeriods, DateAllocationOption);
	UpdateDistributionHint();
	
EndProcedure

&AtClient
Procedure QuantityAllocationOptionOnChange(Item)
	
	If QuantityAllocationOption = "Proportionally" Then
		
		Shares.Clear();
		FillInShares(Shares, NumberOfPeriods, DateAllocationOption);
		
	EndIf; 
	
	SetAccessibilityVisibility();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	If QuantityAllocationOption = "ByShares" And Items.PagesAllocation.CurrentPage = Items.MainGroup3 Then
		
		Items.PagesAllocation.CurrentPage = Items.TheGroupSShare;
		SetAccessibilityVisibility();
		
	Else
		
		// saving the settings
		DistributionParameters = GenerateAndSaveSettingsOnServer();
		
		Close(DistributionParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	Items.PagesAllocation.CurrentPage = Items.MainGroup3;
	SetAccessibilityVisibility();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetAccessibilityVisibility()

	If Operation = "Transfer" Then
		
		Items.OperationPages.CurrentPage = Items.PageTransfer;
		
		UpdateTransferHint();
		
		Items.FormNext.Title = NStr("vi = 'Chuyển sang';
									|ru = 'Перенести';
									|en = 'Move'; fa = 'انتقال';
									|it = 'Spostare';
									|pl = 'Move';
									|tr = 'Taşı'");
		
		Items.DayNumber.Enabled = TransferOption = "ToNumber";
		Items.FirstDayOfTheWeek.Enabled = TransferOption = "OnFirstDayOfWeek";
		Items.LastDayOfTheWeek.Enabled = TransferOption = "OnLastDayOfWeek";
		
	ElsIf Operation = "Allocation" Then
		
		Items.OperationPages.CurrentPage = Items.PageAllocation;
		
		UpdateDistributionHint();
		
		Items.NumberOfPeriods.Enabled = DateAllocationOption = "ByPeriods";
		Items.DayOfTheWeekDistribution.Enabled = DateAllocationOption = "ByWeeks";
		
		If QuantityAllocationOption = "Proportionally" Or Items.PagesAllocation.CurrentPage = Items.TheGroupSShare Then
		
		
			Items.FormNext.Title = NStr("vi = 'Phân bổ';
										|ru = 'Распределить';
										|en = 'Allocate'; fa = 'تسهیم';
										|it = 'Ripartire';
										|pl = 'Allocate';
										|tr = 'Dağıt'");
		
		
		Else
		
			Items.FormNext.Title = NStr("vi = 'Tiếp theo >';
										|ru = 'Далее >';
										|en = 'Next >'; fa = 'بعدی >';
										|it = 'Avanti >';
										|pl = 'Dalej >';
										|tr = 'İleri >'");
		
		EndIf;
		
	EndIf; 
	
	If Operation = "Allocation" 
		And QuantityAllocationOption = "ByShares" 
		And Items.PagesAllocation.CurrentPage = Items.TheGroupSShare Then
		Items.FormBack.Visible = True;
	Else
		Items.FormBack.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateTransferHint()

	If PlanningType = "AssemblyProductionPlanning" Then
		TooltipTemplate = NStr("vi = 'Ví dụ: ngày phát hành %CurDateOfReceipt% sẽ được chuyển sang %NewReceiptDate%.';
								|ru = 'Например, дата выпуска %CurDateOfReceipt% будет перенесена на %NewReceiptDate%.';
								|en = 'For example, release date on %CurDateOfReceipt% will be changed to %NewReceiptDate%.'; fa = 'For example, release date on %CurDateOfReceipt% will be changed to %NewReceiptDate%.';
								|it = 'Ad esempio, la data di rilascio %CurDateOfReceipt%  verrà spostata a %NewReceiptDate%.';
								|pl = 'Na przykład, data wypuszczenia %CurDateOfReceipt% będzie przeniesiona na %NewReceiptDate%.';
								|tr = 'Örnek, %CurDateOfReceipt% üretim tarihi %NewReceiptDate% değiştirilecektir.'");
	ElsIf PlanningType = "DisassemblyProductionPlanning" Then
		TooltipTemplate = NStr("vi = 'Ví dụ: ngày Bắt đầu %CurDateOfReceipt% sẽ được chuyển sang %NewReceiptDate%.';
								|ru = 'Например, дата запуска %CurDateOfReceipt% будет перенесена на %NewReceiptDate%.';
								|en = 'For example, start date %CurDateOfReceipt% will be changed to %NewReceiptDate%.'; fa = 'For example, start date %CurDateOfReceipt% will be changed to %NewReceiptDate%.';
								|it = 'Ad esempio, la data di rilascio %CurDateOfReceipt%  verrà spostata a %NewReceiptDate%.';
								|pl = 'Na przykład, data uruchomienia %CurDateOfReceipt% będzie przeniesiona na %NewReceiptDate%.';
								|tr = 'Örnek, %CurDateOfReceipt% başlangıç tarihi %NewReceiptDate% değiştirilecektir.'");
	ElsIf PlanningType = "PlanningAssemblyDisassembly" Then
		TooltipTemplate = NStr("vi = 'Ví dụ: ngày đóng bộ (tách bộ) %CurDateOfReceipt% sẽ được chuyển sang %NewReceiptDate%.';
								|ru = 'Например, дата сборки (разборки) %CurDateOfReceipt% будет перенесена на %NewReceiptDate%.';
								|en = 'For example, kitting date on %CurDateOfReceipt% will be changed to %NewReceiptDate%.'; fa = 'For example, kitting date on %CurDateOfReceipt% will be changed to %NewReceiptDate%.';
								|it = 'Ad esempio, la data di assemblaggio (smontaggio) %CurDateOfReceipt% verrà spostata a %NewReceiptDate%.';
								|pl = 'Na przykład, data montażu (demontażu) %CurDateOfReceipt% będzie przeniesiona na%NewReceiptDate%.';
								|tr = 'Örnek, %CurDateOfReceipt% montaj (demontaj) %NewReceiptDate% değiştirilecektir.'");
	ElsIf PlanningType = "PlanningTransferOfMaterialsToProduction" Then
		TooltipTemplate = NStr("vi = 'Ví dụ: ngày giao hàng của vật liệu %CurDateOfReceipt% sẽ được chuyển sang %NewReceiptDate%.';
								|ru = 'Например, дата отгрузки материалов %CurDateOfReceipt% будет перенесена на %NewReceiptDate%.';
								|en = 'For example, material shipment date on %CurDateOfReceipt% will be changed to %NewReceiptDate%.'; fa = 'For example, material shipment date on %CurDateOfReceipt% will be changed to %NewReceiptDate%.';
								|it = 'Ad esempio, la data di scarico dei materiali %CurDateOfReceipt% verrà spostata a %NewReceiptDate%.';
								|pl = 'Na przykład, data wysyłki materiałów %CurDateOfReceipt% będzie przeniesiona na %NewReceiptDate%.';
								|tr = 'Örnek, %CurDateOfReceipt% malzeme sevkiyat tarihi %NewReceiptDate% değiştirilecektir.'");
	Else
		TooltipTemplate = NStr("vi = 'Ví dụ: ngày nhận %CurDateOfReceipt% sẽ được chuyển sang %NewReceiptDate%.';
								|ru = 'Например, дата поступления %CurDateOfReceipt% будет перенесена на %NewReceiptDate%.';
								|en = 'For example, receipt date on %CurDateOfReceipt% will be changed to %NewReceiptDate%.'; fa = 'For example, receipt date on %CurDateOfReceipt% will be changed to %NewReceiptDate%.';
								|it = 'Ad esempio, la data dell''entrata %CurDateOfReceipt%  verrà spostata a %NewReceiptDate%.';
								|pl = 'Na przykład, data wpłaty %CurDateOfReceipt% będzie przeniesiona na %NewReceiptDate%.';
								|tr = 'Örnek, %CurDateOfReceipt% giriş tarihi %NewReceiptDate% değiştirilecektir.'");
	EndIf;
	
	If TransferOption = "ToNumber" Then
	
		NewReceiptDate = DateOfReceipt + (DayNumber-1) * 86400;
	
	ElsIf TransferOption = "OnFirstDayOfWeek" Then
		
		WeekDayNumber = WeekDayNumber(WeekDay);
		CurNumberOfDayOfWeek = WeekDay(DateOfReceipt);
		
		If CurNumberOfDayOfWeek > WeekDayNumber Then
		
			NewReceiptDate = DateOfReceipt + (7 + WeekDayNumber - CurNumberOfDayOfWeek) * 86400;
			
		ElsIf CurNumberOfDayOfWeek < WeekDayNumber Then
			NewReceiptDate = DateOfReceipt + (WeekDayNumber - CurNumberOfDayOfWeek) * 86400;
		Else
			NewReceiptDate = DateOfReceipt;
		EndIf; 
		
	ElsIf TransferOption = "OnLastDayOfWeek" Then
		
		WeekDayNumber = WeekDayNumber(WeekDay);
		CurNumberOfDayOfWeek = WeekDay(PlanningClientServerCached.CalculatePeriodEndDate(DateOfReceipt, Periodicity));
		
		If CurNumberOfDayOfWeek > WeekDayNumber Then
		
			NewReceiptDate = PlanningClientServerCached.CalculatePeriodEndDate(DateOfReceipt, Periodicity) - (CurNumberOfDayOfWeek - WeekDayNumber) * 86400;
			
		ElsIf CurNumberOfDayOfWeek < WeekDayNumber Then
			NewReceiptDate = PlanningClientServerCached.CalculatePeriodEndDate(DateOfReceipt, Periodicity) - (7 - WeekDayNumber + CurNumberOfDayOfWeek) * 86400;
		Else
			NewReceiptDate = PlanningClientServerCached.CalculatePeriodEndDate(DateOfReceipt, Periodicity);
		EndIf;
	
	EndIf; 
	
	TooltipTemplate = StrReplace(TooltipTemplate, "%CurDateOfReceipt%", Format(DateOfReceipt, "DLF=D"));
	TooltipTemplate = StrReplace(TooltipTemplate, "%NewReceiptDate%", Format(NewReceiptDate, "DLF=D"));
	TransferTooltip = TooltipTemplate;

EndProcedure 

&AtClient
Procedure UpdateDistributionHint()
	
	If DateAllocationOption = "ByWeeks" Then
		
		If PlanningType = "AssemblyProductionPlanning" Then
			TooltipTemplate = NStr("vi = 'Ví dụ: bản phát hành %CurDateOfReceipt% được phân bổ theo %NumberOfPeriods% của kỳ, tùy thuộc vào tháng cụ thể. Bản phát hành sẽ ở %WeekDay%.';
									|ru = 'Например, выпуск %CurDateOfReceipt% распределен на %NumberOfPeriods% периода(ов), в зависимости от конкретного месяца. Выпуск будет в %WeekDay%.';
									|en = 'For example, release on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods depending on a month. The release will be on %WeekDay%.'; fa = 'For example, release on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods depending on a month. The release will be on %WeekDay%.';
									|it = 'Ad esempio, il rilascio %CurDateOfReceipt% è ridistribuito su %NumberOfPeriods% periodo(i), in relazione al mese concreto. Il rilascio avverrà %WeekDay%.';
									|pl = 'Na przykład, wypuszczenie %CurDateOfReceipt% przydzielono na %NumberOfPeriods% okres (ów), w zależności od konkretnego miesiąca. Wypuszczenie będzie w%WeekDay%.';
									|tr = 'Örnek, %CurDateOfReceipt% üretimi %NumberOfPeriods% dönemine (dönemlerine) belli aya bağımlı kalmadan dağıtıldı. Üretim %WeekDay% olacaktır.'");
		ElsIf PlanningType = "DisassemblyProductionPlanning" Then
			TooltipTemplate = NStr("vi = 'Ví dụ, việc bắt đầu xuất xưởng %CurDateOfReceipt% được phân bổ theo %NumberOfPeriods% của kỳ, tùy thuộc vào tháng cụ thể. Việc bắt đầu xuất xưởng sẽ ở %WeekDay%.';
									|ru = 'Например, запуск %CurDateOfReceipt% распределен на %NumberOfPeriods% периода(ов), в зависимости от конкретного месяца. Запуск будет в %WeekDay%.';
									|en = 'For example, launch %CurDateOfReceipt% is allocated to %NumberOfPeriods% period(s) depending on a specific month. Launch will be on %WeekDay%.'; fa = 'For example, launch %CurDateOfReceipt% is allocated to %NumberOfPeriods% period(s) depending on a specific month. Launch will be on %WeekDay%.';
									|it = 'Ad esempio, l''avvio %CurDateOfReceipt%  è ridistribuito su %NumberOfPeriods% periodo(i), in relazione al mese concreto. L''avvio avverrà %WeekDay%.';
									|pl = 'Na przykład, uruchomienie %CurDateOfReceipt% przydzielone na %NumberOfPeriods% okres (ów), w zależności od konkretnego miesiąca. Uruchomienie będzie w %WeekDay%.';
									|tr = 'Örnek, %CurDateOfReceipt% başlatılması %NumberOfPeriods% dönemine (dönemlerine) belli aya bağımlı kalmadan dağıtıldı. Başlatma %WeekDay% olacaktır.'");
		ElsIf PlanningType = "PlanningAssemblyDisassembly" Then
			TooltipTemplate = NStr("vi = 'Ví dụ: đóng bộ (tách bộ) %CurDateOfReceipt% được phân bổ cho %NumberOfPeriods% kỳ, tùy thuộc vào tháng cụ thể. Đóng bộ (tách bộ) sẽ vào ngày %WeekDay%.';
									|ru = 'Например, сборка(разборка) %CurDateOfReceipt% распределена на %NumberOfPeriods% периода(ов), в зависимости от конкретного месяца. Сборка (разборка) будет в %WeekDay%.';
									|en = 'For example, kitting on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods depending on a month. Kitting will be on %WeekDay%.'; fa = 'For example, kitting on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods depending on a month. Kitting will be on %WeekDay%.';
									|it = 'Ad esempio, l''assemblaggio (smontaggio) %CurDateOfReceipt%  è ridistribuito su %NumberOfPeriods%  periodo(i), in relazione al mese concreto. L''assemblaggio (smontaggio) avverrà %WeekDay%.';
									|pl = 'Na przykład, montaż (demontaż) %CurDateOfReceipt% przydzielono na %NumberOfPeriods% okres (ów), w zależności od konkretnego miesiąca. Montaż (demontaż) będzie w%WeekDay%.';
									|tr = 'Örnek, %CurDateOfReceipt% montaj(demontaj) %NumberOfPeriods% dönemine (dönemlerine), belli aya bağımlı kalmadan dağıtıldı. Montaj (demontaj) %WeekDay% olacaktır.'");
		ElsIf PlanningType = "PlanningTransferOfMaterialsToProduction" Then
			TooltipTemplate = NStr("vi = 'Ví dụ, việc giao hàng nguyên vật liệu %CurDateOfReceipt% được phân bổ theo %NumberOfPeriods% của kỳ, tùy thuộc vào tháng cụ thể. Đóng bộ (tách bộ) sẽ vào ngày %WeekDay%.';
									|ru = 'Например, отгрузка материалов %CurDateOfReceipt% распределена на %NumberOfPeriods% периода(ов), в зависимости от конкретного месяца. Сборка (разборка) будет в %WeekDay%.';
									|en = 'For example, material shipment on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods depending on a month. Kitting will be on %WeekDay%.'; fa = 'For example, material shipment on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods depending on a month. Kitting will be on %WeekDay%.';
									|it = 'Ad esempio, lo scarico dei materiali %CurDateOfReceipt% è ridistribuito su %NumberOfPeriods% periodo(i), in relazione al mese concreto. Lo scarico dei materiali avverrà %WeekDay%.';
									|pl = 'Na przykład, wysyłkę materiałów %CurDateOfReceipt% przydzielono na %NumberOfPeriods% okres (ów), w zależności od konkretnego miesiąca. Montaż (demontaż) będzie w%WeekDay%.';
									|tr = 'Örnek, %CurDateOfReceipt% malzeme sevkiyatı %NumberOfPeriods% dönemine (dönemlerine), belli aya bağımlı kalmadan dağıtıldı. Montaj (demontaj) %WeekDay% olacaktır.'");
		Else
			TooltipTemplate = NStr("vi = 'Ví dụ: việc tiếp nhận %CurDateOfReceipt% được phân bổ theo %NumberOfPeriods% của kỳ, tùy thuộc vào tháng cụ thể. Việc tiếp nhận sẽ có trong %WeekDay%.';
									|ru = 'Например, поступление %CurDateOfReceipt% распределено на %NumberOfPeriods% периода(ов), в зависимости от конкретного месяца. Поступления будут в %WeekDay%.';
									|en = 'For example, the receipt on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods depending on a month. Receipts will be on %WeekDay%.'; fa = 'For example, the receipt on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods depending on a month. Receipts will be on %WeekDay%.';
									|it = 'Ad esempio, l''entrata %CurDateOfReceipt% è ridistribuita su  %NumberOfPeriods% periodo(i), in relazione al mese concreto. Le entrate avverranno %WeekDay%.';
									|pl = 'Na przykład, wpływ %CurDateOfReceipt% przydzielono na %NumberOfPeriods% okres (ów), w zależności od konkretnego miesiąca. Wpływy będą w%WeekDay%.';
									|tr = 'Örnek, %CurDateOfReceipt% giriş %NumberOfPeriods% dönemine (dönemlerine), belli aya bağımlı kalmadan dağıtıldı. Giriş %WeekDay% olacaktır.'");
		EndIf;
		StringNumberOfPeriods = Format(NumberOfPeriods, "NFD=; NG=0");
		TooltipTemplate = StrReplace(TooltipTemplate, "%NumberOfPeriods%", StringNumberOfPeriods);
		TooltipTemplate = StrReplace(TooltipTemplate, "%WeekDay%", Items.DayOfTheWeekDistribution.ChoiceList.FindByValue(WeekDay).Presentation);
		
	ElsIf DateAllocationOption = "ByTenDayPeriods" Then
		
		If PlanningType = "AssemblyProductionPlanning" Then
			TooltipTemplate = NStr("vi = 'Ví dụ, việc xuất xưởng %CurDateOfReceipt% được phân bổ trong 30 ngày. Ngày xuất xưởng được thiết lập vào ngày 1, 11 và 21 của tháng.';
									|ru = 'Например, выпуск %CurDateOfReceipt% распределен на 3 декады. Даты выпуска установлены на 1, 11 и 21 число месяца.';
									|en = 'For example, release on %CurDateOfReceipt% is allocated to 3 ten-day periods. The release dates are set to the 1st, 11th and 21st days of the month.'; fa = 'For example, release on %CurDateOfReceipt% is allocated to 3 ten-day periods. The release dates are set to the 1st, 11th and 21st days of the month.';
									|it = 'Ad esempio, il rilascio %CurDateOfReceipt%  è ridistribuito su 3 decenni. Le date del rilascio sono impostate al 1o, 11o e 21o giorno del mese.';
									|pl = 'Na przykład, wpływ %CurDateOfReceipt% przydzielono na 3 dekady. Daty wpływu są ustawione na 1, 11 i 21 dzień miesiąca.';
									|tr = 'Örneğin, %CurDateOfReceipt% üretimi 3 on günlük süreye dağıtıldı. Üretim tarihleri ​​ayın 1''i, 11''i ve 21''i olarak belirlendi.'");
		ElsIf PlanningType = "DisassemblyProductionPlanning" Then
			TooltipTemplate = NStr("vi = 'Ví dụ, việc bắt đầu xuất xưởng%CurDateOfReceipt% được phân bổ trong 30 ngày. Ngày bắt đầu xuất xưởng được ấn định vào ngày 1, 11 và 21 của tháng.';
									|ru = 'Например, запуск %CurDateOfReceipt% распределен на 3 декады. Даты запуска установлены на 1, 11 и 21 число месяца.';
									|en = 'For example, launch on %CurDateOfReceipt% is allocated to 3 ten-day periods. Launch dates are set to the 1st, 11th, and 21st day of the month.'; fa = 'For example, launch on %CurDateOfReceipt% is allocated to 3 ten-day periods. Launch dates are set to the 1st, 11th, and 21st day of the month.';
									|it = 'Ad esempio, l''avvio %CurDateOfReceipt%  è ridistribuito su 3 decenni. Le date dell''avvio sono impostate al 1o, 11o e 21o giorno del mese.';
									|pl = 'Na przykład, uruchomienie %CurDateOfReceipt% przydzielono na 3 dekady. Daty uruchomienia są ustawione na1, 11 i 21 dzień miesiąca.';
									|tr = 'Örneğin, %CurDateOfReceipt% başlatılması 3 on günlük süreye dağıtıldı. Başlatma tarihleri ​​ayın 1''i, 11''i ve 21''i olarak belirlendi.'");
		ElsIf PlanningType = "PlanningAssemblyDisassembly" Then
			TooltipTemplate = NStr("vi = 'Ví dụ, việc đóng bộ (tách bộ) vào ngày %CurDateOfReceipt% được phân bổ trong 30 ngày. Ngày lắp ráp (tháo gỡ) được đặt vào ngày 1, 11 và 21 của tháng.';
									|ru = 'Например, сборка (разборка) %CurDateOfReceipt% распределена на 3 декады. Даты сборок (разборок) установлены на 1, 11 и 21 число месяца.';
									|en = 'For example, kitting on %CurDateOfReceipt% is allocated to 3 ten-day periods. Kitting dates are set to the 1st, 11th and 21st days of the month.'; fa = 'For example, kitting on %CurDateOfReceipt% is allocated to 3 ten-day periods. Kitting dates are set to the 1st, 11th and 21st days of the month.';
									|it = 'Ad esempio, l''assemblaggio (smontaggio) %CurDateOfReceipt%  è ridistribuito su 3 decenni. Le date dell''assemblaggio (smontaggio) sono impostate al 1o, 11o e 21o giorno del mese.';
									|pl = 'Na przykład, montaż (demontaż) %CurDateOfReceipt% przydzielono na 3 dekady. Daty montażu (demontażu) są ustawione na 1, 11 i 21 dzień miesiąca.';
									|tr = 'Örneğin, %CurDateOfReceipt% montaj (demontaj) 3 on günlük süreye dağıtıldı. Montaj (demontaj) tarihleri ​​ayın 1''i, 11''i ve 21''i olarak belirlendi.'");
		ElsIf PlanningType = "PlanningTransferOfMaterialsToProduction" Then
			TooltipTemplate = NStr("vi = 'Ví dụ, việc giao nguyên vật liệu %CurDateOfReceipt% được phân bổ trong 30 ngày. Ngày đóng bộ (tách bộ) được đặt vào ngày 1, 11 và 21 của tháng.';
									|ru = 'Например, отгрузка материалов %CurDateOfReceipt% распределена на 3 декады. Даты сборок (разборок) установлены на 1, 11 и 21 число месяца.';
									|en = 'For example, material shipment on %CurDateOfReceipt% is allocated to 3 ten-day periods. Kitting dates are set to the 1st, 11th and 21st days of the month.'; fa = 'For example, material shipment on %CurDateOfReceipt% is allocated to 3 ten-day periods. Kitting dates are set to the 1st, 11th and 21st days of the month.';
									|it = 'Ad esempio, lo scarico dei materiali %CurDateOfReceipt% è ridistribuito su 3 decenni. Le date dell''assemblaggio (smontaggio) sono impostate al 1o, 11o e 21o giorno del mese.';
									|pl = 'Na przykład, wysyłka materiałów %CurDateOfReceipt% przydzielono na 3 dekady. Daty montażu (demontażu) są ustawione na 1, 11 i 21 dzień miesiąca.';
									|tr = 'Örneğin, %CurDateOfReceipt% malzeme sevkiyatı 3 on günlük süreye dağıtıldı. Montaj (demontaj) tarihleri ​​ayın 1''i, 11''i ve 21''i olarak belirlendi.'");
		Else
			TooltipTemplate = NStr("vi = 'Ví dụ, việc tiếp nhận%CurDateOfReceipt% được phân bổ trong 30 ngày. Ngày tiếp nhận được đặt vào ngày 1, 11 và 21 của tháng.';
									|ru = 'Например, поступление %CurDateOfReceipt% распределено на 3 декады. Даты поступления установлены на 1, 11 и 21 число месяца.';
									|en = 'For example, the receipt on %CurDateOfReceipt% is allocated to 3 ten-day periods. The receipt dates are set to the 1st, 11th and 21st days of the month.'; fa = 'For example, the receipt on %CurDateOfReceipt% is allocated to 3 ten-day periods. The receipt dates are set to the 1st, 11th and 21st days of the month.';
									|it = 'Ad esempio, l''entrata %CurDateOfReceipt%  è ridistribuito su 3 decenni. Le date dell''entrata sono impostate al 1o, 11o e 21o giorno del mese.';
									|pl = 'Na przykład, wpływ %CurDateOfReceipt% przydzielono na 3 dekady. Daty wpływu są ustawione na 1, 11 i 21 dzień miesiąca.';
									|tr = 'Örneğin, %CurDateOfReceipt% girişleri 3 on günlük süreye dağıtıldı. Giriş için tarihleri ​​ayın 1''i, 11''i ve 21''i olarak belirlendi.'");
		EndIf;
		
	ElsIf DateAllocationOption = "ByPeriods" Then
		
		If PlanningType = "AssemblyProductionPlanning" Then
			TooltipTemplate = NStr("vi = 'Ví dụ, việc xuất xưởng %CurDateOfReceipt% được phân bổ theo %NumberOfPeriods% của kỳ. Ngày phát hành được đặt vào ngày đầu tiên của mỗi kỳ.';
									|ru = 'Например, выпуск %CurDateOfReceipt% распределен на %NumberOfPeriods% периода(ов). Даты выпуска установлены первый день каждого периода.';
									|en = 'For example, release on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods. The release dates are set to the first day of each period.'; fa = 'For example, release on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods. The release dates are set to the first day of each period.';
									|it = 'Ad esempio, il rilascio %CurDateOfReceipt%  è ridistribuito su %NumberOfPeriods% periodo(i). Le date del rilascio sono impostate al primo giorno di ogni periodo.';
									|pl = 'Na przykład, wypuszczenie %CurDateOfReceipt% przydzielono na %NumberOfPeriods% okres (ów). Daty wypuszczenia są ustawione na pierwszy dzień każdego okresu.';
									|tr = 'Örnek, %CurDateOfReceipt% üretimi %NumberOfPeriods% dönem (dönemlerine) dağıtıldı. Üretim tarihleri her dönemin ilk gününe ayarlandı.'");
		ElsIf PlanningType = "DisassemblyProductionPlanning" Then
			TooltipTemplate = NStr("vi = 'Ví dụ, việc bắt đầu xuất xưởng%CurDateOfReceipt% được phân bổ theo %NumberOfPeriods% của kỳ. Ngày bắt đầu xuất xưởng được thiết lập vào ngày đầu tiên của mỗi kỳ.';
									|ru = 'Например, запуск %CurDateOfReceipt% распределен на %NumberOfPeriods% периода(ов). Даты запуска установлены первый день каждого периода.';
									|en = 'For example, launch %CurDateOfReceipt% is allocated to %NumberOfPeriods% period(s). Launch dates are set to the first day of each period.'; fa = 'For example, launch %CurDateOfReceipt% is allocated to %NumberOfPeriods% period(s). Launch dates are set to the first day of each period.';
									|it = 'Ad esempio, l''avvio %CurDateOfReceipt% è ridistribuito su  %NumberOfPeriods% periodo(i). Le date di avvio sono impostate al primo giorno di ogni periodo.';
									|pl = 'Na przykład, uruchomienie %CurDateOfReceipt% przydzielono na %NumberOfPeriods% okres (ów). Daty uruchomienia są ustawione na pierwszy dzień każdego okresu.';
									|tr = 'Örnek, %CurDateOfReceipt% başlatılması %NumberOfPeriods% dönem (dönemlerine) dağıtıldı. Başlatma tarihleri her dönemin ilk gününe ayarlandı.'");
		ElsIf PlanningType = "PlanningAssemblyDisassembly" Then
			TooltipTemplate = NStr("vi = 'Ví dụ, việc đóng bộ (tách bộ) %CurDateOfReceipt% được phân bổ theo %NumberOfPeriods% của kỳ. Ngày đóng bộ (tách bộ) được đặt vào ngày đầu tiên của mỗi kỳ.';
									|ru = 'Например, сборка (разборка) %CurDateOfReceipt% распределена на %NumberOfPeriods% периода(ов). Даты сборок (разборок) установлены первый день каждого периода.';
									|en = 'For example, kitting on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods. Kitting dates are set to the first day of each period.'; fa = 'For example, kitting on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods. Kitting dates are set to the first day of each period.';
									|it = 'Ad esempio, l''assemblaggio (smontaggio) %CurDateOfReceipt% è ridistribuito su %NumberOfPeriods% periodo(i). Le date di assemblaggio (smontaggio) sono impostate al primo giorno di ogni periodo.';
									|pl = 'Na przykład, montaż (demontaż) %CurDateOfReceipt% przydzielono na %NumberOfPeriods% okres (ów). Daty montaży (demontaży) są ustawione na pierwszy dzień każdego okresu.';
									|tr = 'Örnek, %CurDateOfReceipt% montaj (demontaj) %NumberOfPeriods% dönem (dönemlerine) dağıtıldı. Montaj (demontaj) tarihleri her dönemin ilk gününe ayarlandı.'");
		ElsIf PlanningType = "PlanningTransferOfMaterialsToProduction" Then
			TooltipTemplate = NStr("vi = 'Ví dụ, việc giao nguyên vật liệu %CurDateOfReceipt% được phân bổ cho %NumberOfPeriods% của kỳ. Ngày đóng bộ (tách bộ) được đặt vào ngày đầu tiên của mỗi kỳ.';
									|ru = 'Например, отгрузка материалов %CurDateOfReceipt% распределена на %NumberOfPeriods% периода(ов). Даты сборок (разборок) установлены первый день каждого периода.';
									|en = 'For example, material shipment on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods depending on a month. Kitting dates are set to the first day of each period.'; fa = 'For example, material shipment on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods depending on a month. Kitting dates are set to the first day of each period.';
									|it = 'Ad esempio, lo scarico dei materiali %CurDateOfReceipt% è ridistribuito su %NumberOfPeriods% periodo(i). Le date di assemblaggio (smontaggio) sono impostate al primo giorno di ogni periodo.';
									|pl = 'Na przykład, wysyłka materiałów %CurDateOfReceipt% przydzielono na %NumberOfPeriods% okres (ów). Daty montaży (demontaży) są ustawione na pierwszy dzień każdego okresu.';
									|tr = 'Örnek, %CurDateOfReceipt% malzeme sevkiyatı %NumberOfPeriods% dönem (dönemlerine) dağıtıldı. Montaj (demontaj) tarihleri her dönemin ilk gününe ayarlandı.'");
		Else
			TooltipTemplate = NStr("vi = 'Ví dụ, việc tiếp nhận %CurDateOfReceipt% được phân bổ theo %NumberOfPeriods% của kỳ. Ngày nhận được đặt vào ngày đầu tiên của mỗi kỳ.';
									|ru = 'Например, поступление %CurDateOfReceipt% распределено на %NumberOfPeriods% периода(ов). Даты поступления установлены первый день каждого периода.';
									|en = 'For example, the receipt on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods. The receipt dates are set to the first day of each period.'; fa = 'For example, the receipt on %CurDateOfReceipt% is allocated to %NumberOfPeriods% periods. The receipt dates are set to the first day of each period.';
									|it = 'Ad esempio, le entrate%CurDateOfReceipt% è ridistribuito su %NumberOfPeriods% periodo(i). Le date dell''entrata sono impostate al primo giorno di ogni periodo.';
									|pl = 'Na przykład, wpływ %CurDateOfReceipt% przydzielono na %NumberOfPeriods% okres (ów). Daty wpływów są ustawione na pierwszy dzień każdego okresu.';
									|tr = 'Örnek, %CurDateOfReceipt% girişler %NumberOfPeriods% dönem (dönemlerine) dağıtıldı. Giriş tarihleri her dönemin ilk gününe ayarlandı.'");
		EndIf;
		StringNumberOfPeriods = Format(NumberOfPeriods, "NFD=; NG=0") ;
		TooltipTemplate = StrReplace(TooltipTemplate, "%NumberOfPeriods%", StringNumberOfPeriods);
		
	EndIf;
	
	TooltipTemplate = StrReplace(TooltipTemplate, "%CurDateOfReceipt%", Format(DateOfReceipt, "DLF=D"));
	TooltipAllocation = TooltipTemplate;

EndProcedure 

&AtClientAtServerNoContext
Function WeekDayNumber(WeekDay)

	Return PlanningClientServer.WeekDayNumber(WeekDay);

EndFunction 

&AtClientAtServerNoContext
Procedure FillInShares(Shares, NumberOfPeriods, DateAllocationOption)
	
	If DateAllocationOption = "ByHalfYearPeriods" Then
		
		PeriodPresentation = NStr("vi = 'nửa năm';
									|ru = 'полугодие';
									|en = 'half-year'; fa = 'نیم‌سال';
									|it = 'semestre';
									|pl = 'półrocze';
									|tr = 'yarıyıl'");
		PresentationOfLastPeriod = NStr("vi = 'nửa năm';
										|ru = 'полугодие';
										|en = 'half-year'; fa = 'نیم‌سال';
										|it = 'semestre';
										|pl = 'półrocze';
										|tr = 'yarıyıl'");
		
	ElsIf DateAllocationOption = "ByQuarters" Then
		
		PeriodPresentation = NStr("vi = 'quý';
									|ru = 'квартал';
									|en = 'quarter'; fa = 'quarter';
									|it = 'trimestre';
									|pl = 'kwartał';
									|tr = 'çeyrek'");
		PresentationOfLastPeriod = NStr("vi = 'quý';
										|ru = 'квартал';
										|en = 'quarter'; fa = 'quarter';
										|it = 'trimestre';
										|pl = 'kwartał';
										|tr = 'çeyrek'");
		
	ElsIf DateAllocationOption = "ByMonths" Then
		
		PeriodPresentation = NStr("vi = 'tháng';
									|ru = 'месяц';
									|en = 'month'; fa = 'ماه';
									|it = 'mese';
									|pl = 'miesiąc';
									|tr = 'ay'");
		PresentationOfLastPeriod = NStr("vi = 'tháng';
										|ru = 'месяц';
										|en = 'month'; fa = 'ماه';
										|it = 'mese';
										|pl = 'miesiąc';
										|tr = 'ay'");
		
	ElsIf DateAllocationOption = "ByWeeks" Then
		
		PeriodPresentation = NStr("vi = 'tuần';
									|ru = 'неделя';
									|en = 'week'; fa = 'هفته';
									|it = 'settimana';
									|pl = 'tydzień';
									|tr = 'hafta'");
		PresentationOfLastPeriod = NStr("vi = 'tuần (nếu có)';
										|ru = 'неделя (если есть)';
										|en = 'week (if any)'; fa = 'week (if any)';
										|it = 'settimana (se presente)';
										|pl = 'tydzień (jeżeli jest)';
										|tr = 'hafta (eğer varsa)'");
		
	ElsIf DateAllocationOption = "ByTenDayPeriods" Then
		
		PeriodPresentation = NStr("vi = '10 ngày';
									|ru = 'декада';
									|en = 'ten-day period'; fa = 'ten-day period';
									|it = 'decade';
									|pl = 'dekada';
									|tr = '10 günlük süre'");
		PresentationOfLastPeriod = NStr("vi = '10 ngày';
										|ru = 'декада';
										|en = 'ten-day period'; fa = 'ten-day period';
										|it = 'decade';
										|pl = 'dekada';
										|tr = '10 günlük süre'");
		
	ElsIf DateAllocationOption = "ByPeriods" Then
		
		PeriodPresentation = NStr("vi = 'kỳ';
									|ru = 'период';
									|en = 'period'; fa = 'period';
									|it = 'periodo';
									|pl = 'okres';
									|tr = 'dönem'");
		PresentationOfLastPeriod = NStr("vi = 'kỳ (nếu có)';
										|ru = 'период (если есть)';
										|en = 'period (if any)'; fa = 'period (if any)';
										|it = 'periodo (se presente)';
										|pl = 'okres (jeżeli jest)';
										|tr = 'dönem (eğer varsa)'");
		
	EndIf;
	
	If NumberOfPeriods = Shares.Count() Then
		
		For Each TSRow In Shares Do
			
			Period = Shares.IndexOf(TSRow) + 1;
			TSRow.Period = Period;
			If NumberOfPeriods = Period Then
				TSRow.Presentation = String(Period) + " " + PresentationOfLastPeriod;
			Else
				TSRow.Presentation = String(Period) + " " + PeriodPresentation;
			EndIf;
			If DateAllocationOption = "ByTenDayPeriods" Then
				If (Period % 3) = 1  Then
					TSRow.Presentation = TSRow.Presentation + NStr("vi = ': từ 1 đến 10';
																	|ru = ': с 1 по 10';
																	|en = ': 1st to 10th'; fa = ': 1st to 10th';
																	|it = ': da 1 a 10';
																	|pl = ': od 1 do 10';
																	|tr = ': 1''den 10''na kadar'");
				ElsIf (Period % 3) = 2 Then
					TSRow.Presentation = TSRow.Presentation + NStr("vi = ': từ 11 đến 20';
																	|ru = ': с 11 по 20';
																	|en = ': 11th to 20th'; fa = ': 11th to 20th';
																	|it = ': da 11 a 20';
																	|pl = ': od 11 do 20';
																	|tr = ': 11''den 20''ne kadar'");
				Else
					TSRow.Presentation = TSRow.Presentation + NStr("vi = ': từ 21';
																	|ru = ': с 21';
																	|en = ': 21th to end of month'; fa = ': 21th to end of month';
																	|it = ': da 21';
																	|pl = ': od 21';
																	|tr = ': 21''den'");
				EndIf; 
			EndIf;
		EndDo; 
	Else
	
		Shares.Clear();
		
		For Period =1 To NumberOfPeriods Do
			
			NewRow = Shares.Add();
			
			NewRow.Period = Period;
			If NumberOfPeriods = Period Then
				NewRow.Presentation = String(Period) + " " + PresentationOfLastPeriod;
			Else
				NewRow.Presentation = String(Period) + " " + PeriodPresentation;
			EndIf; 
			NewRow.Share = 1;
			If DateAllocationOption = "ByTenDayPeriods" Then
				If (Period % 3) = 1  Then
					NewRow.Presentation = NewRow.Presentation + NStr("vi = ': từ 1 đến 10';
																	|ru = ': с 1 по 10';
																	|en = ': 1st to 10th'; fa = ': 1st to 10th';
																	|it = ': da 1 a 10';
																	|pl = ': od 1 do 10';
																	|tr = ': 1''den 10''na kadar'");
				ElsIf (Period % 3) = 2 Then
					NewRow.Presentation = NewRow.Presentation + NStr("vi = ': từ 11 đến 20';
																	|ru = ': с 11 по 20';
																	|en = ': 11th to 20th'; fa = ': 11th to 20th';
																	|it = ': da 11 a 20';
																	|pl = ': od 11 do 20';
																	|tr = ': 11''den 20''ne kadar'");
				Else
					NewRow.Presentation = NewRow.Presentation + NStr("vi = ': từ 21';
																	|ru = ': с 21';
																	|en = ': 21th to end of month'; fa = ': 21th to end of month';
																	|it = ': da 21';
																	|pl = ': od 21';
																	|tr = ': 21''den'");
				EndIf; 
			EndIf;
		EndDo; 
	
	EndIf; 

EndProcedure

&AtClientAtServerNoContext
Procedure CalculateNumberOfDefaultPeriods(NumberOfPeriods, Periodicity, DateAllocationOption, DateOfReceipt, WeekDay)

	If DateAllocationOption = "ByPeriods" Then
		Return;
	EndIf;
	
	If DateAllocationOption = "ByHalfYearPeriods" Then
		
		If Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
			NumberOfPeriods = 2;
		Else
			NumberOfPeriods = 1;
		EndIf; 
		
	ElsIf DateAllocationOption = "ByQuarters" Then
		
		If Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
			NumberOfPeriods = 4;
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
			NumberOfPeriods = 2;
		Else
			NumberOfPeriods = 1;
		EndIf; 
		
	ElsIf DateAllocationOption = "ByMonths" Then
		
		If Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
			NumberOfPeriods = 12;
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
			NumberOfPeriods = 6;
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
			NumberOfPeriods = 3;
		Else
			NumberOfPeriods = 1;
		EndIf; 
		
	ElsIf DateAllocationOption = "ByWeeks" Then
		
		If Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
			NumberOfPeriods = 54;
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
			NumberOfPeriods = 27;
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
			NumberOfPeriods = 14;
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
			
			WeekDayNumber = WeekDayNumber(WeekDay);
			BeginOfPeriod = PlanningClientServerCached.CalculateStartDateOfPeriod(DateOfReceipt, Periodicity);
			PeriodEnding = PlanningClientServerCached.CalculatePeriodEndDate(DateOfReceipt, Periodicity);
				
			CurDayOfWeek = WeekDay(BeginOfPeriod);
			If CurDayOfWeek <= WeekDayNumber Then
				FirstPeriod = BeginOfPeriod  + (WeekDayNumber - CurDayOfWeek) * 86400;
			Else
				FirstPeriod = EndOfWeek(BeginOfPeriod) + 1 + (WeekDayNumber -1) * 86400;
			EndIf;
			
			CurDayOfWeek = WeekDay(PeriodEnding);
			If CurDayOfWeek >= WeekDayNumber Then
				LastPeriod = BegOfWeek(PeriodEnding) + (WeekDayNumber -1) * 86400;
			Else
				LastPeriod = BegOfWeek(PeriodEnding)- (8 - WeekDayNumber) * 86400;
			EndIf;
			
			NumberOfPeriods = Int((LastPeriod - FirstPeriod) / 604800) + 1;
			
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
			NumberOfPeriods = 2;
		Else
			NumberOfPeriods = 1;
		EndIf; 
		
	ElsIf DateAllocationOption = "ByTenDayPeriods" Then
	
		If Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
			NumberOfPeriods = 36;
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
			NumberOfPeriods = 18;
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
			NumberOfPeriods = 9;
		ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
			NumberOfPeriods = 3;
		Else
			NumberOfPeriods = 1;
		EndIf; 
	
	EndIf;
	
EndProcedure

&AtServer
Function GenerateAndSaveSettingsOnServer()
	
	DistributionParameters = New Structure;
	DistributionParameters.Insert("Operation", Operation);
	
	DistributionParameters.Insert("TransferOption", TransferOption);
	DistributionParameters.Insert("DayNumber", DayNumber);
	DistributionParameters.Insert("WeekDay", WeekDay);
	DistributionParameters.Insert("PlanningType", PlanningType);
	DistributionParameters.Insert("Periodicity", Periodicity);
	
	DistributionParameters.Insert("DateAllocationOption", DateAllocationOption);
	DistributionParameters.Insert("NumberOfPeriods", NumberOfPeriods);
	DistributionParameters.Insert("QuantityAllocationOption", QuantityAllocationOption);
	DistributionParameters.Insert("RoundingPrecision", RoundingPrecision);
	DistributionParameters.Insert("SelectToOrder", SelectToOrder);
	DistributionParameters.Insert("Shares", Shares.Unload(,"Share").UnloadColumn("Share"));
	
	// We save the settings in the context of the scenario
	
	Common.FormDataSettingsStorageSave(
		String(Scenario.UUID())+PlanningType,
		"DistributionParameters",
		DistributionParameters);
	
	Return DistributionParameters;

EndFunction
 
#EndRegion
