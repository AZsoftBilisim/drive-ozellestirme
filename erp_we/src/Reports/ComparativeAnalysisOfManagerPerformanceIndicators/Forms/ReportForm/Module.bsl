
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	GettingRequiredFOValues();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If SettingsVersion <> CurVersionOfSettings() Then
		FillDataSetTree();
		SettingsVersion = CurVersionOfSettings();
	Else
		SetVisibilityOfIndicatorsDependingOnFO();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	Settings = New Structure;
	Settings.Insert("Filter_Settings",Report.SettingsComposer.GetSettings());
	
	Common.CommonSettingsStorageSave("Report.ComparativeAnalysisOfManagerPerformanceIndicators", "ReportForm", Settings);
	
EndProcedure

&AtServer
Procedure OnLoadVariantAtServer(Settings)
	
	SchemeForUserFilter = Reports.ComparativeAnalysisOfManagerPerformanceIndicators.GetTemplate("SchemeForUserFilter");
	SchemaURL = PutToTempStorage(SchemeForUserFilter,UUID);
	Report.SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL)); 
	
	SettingsValue = Common.CommonSettingsStorageLoad("Report.ComparativeAnalysisOfManagerPerformanceIndicators", "ReportForm");
	If SettingsValue <> Undefined 
	     And SettingsValue.Property("Filter_Settings")
	     And SettingsValue.Filter_Settings <> Undefined Then
	     	
		Report.SettingsComposer.LoadSettings(SettingsValue.Filter_Settings);
		Report.SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	Cancel = SelectionsAndSettingsAreFilledInIncorrectly();
	
	If Not Cancel Then
		GenerateReport();
	EndIf;
EndProcedure

&AtClient
Procedure Settings(Command)
	
	ParametersForSettingsForm = StructureOfSettingsForm();
	Result = Undefined;

	OpenForm("Report.ComparativeAnalysisOfManagerPerformanceIndicators.Form.SettingsChoice",ParametersForSettingsForm,ThisForm,,,, New CallbackDescription("SettingsCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SettingsCompletion(Result, AdditionalParameters) Export
    
    If Result <> Undefined Then
        
        DisplayCharts         = Result.DisplayCharts;
        DisplayLegend           = Result.DisplayLegend;
        DisplayTables           = Result.DisplayTables;
        InterestRate          = Result.InterestRate;
        Report.SettingsComposer = Result.CompositionSettings;
        ProcessResultOnServer(Result.Indicators);
        
    EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Function StructureReportGenerationParameters()
	
	ParametersStructure = New Structure();
	
	ParametersStructure.Insert("AdditionalPeriodForAnalysis",AdditionalPeriodForAnalysis);
	ParametersStructure.Insert("ReportGenerationPeriod",ReportGenerationPeriod);
	ParametersStructure.Insert("InterestRate",InterestRate);
	ParametersStructure.Insert("DisplayCharts",DisplayCharts);
	ParametersStructure.Insert("DisplayLegend",DisplayLegend);
	ParametersStructure.Insert("DisplayTables",DisplayTables);
	ParametersStructure.Insert("TreeOfDataSets",TemporaryStorageOfSettingsOnServer());
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Procedure GettingRequiredFOValues()

	RecordCustomerClaims = GetFunctionalOption("RecordComplaints");
	UseInteraction = GetFunctionalOption("UseEmailClient");
	RecordInitialRequest = GetFunctionalOption("RecordInitialRequest");
	UseSalesOpportunitiesToCustomer = GetFunctionalOption("UseSalesOpportunitiesToCustomer");
	UseDiscountAdjustmentsInSales = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	PartnerClassificationIsUsed = GetFunctionalOption("UseABCXYZClassificationOfPartnersByGrossProfit") 
	                                     Or GetFunctionalOption("UseABCXYZClassificationOfPartnersByRevenue")
	                                     Or GetFunctionalOption("UseABCXYZClassificationOfPartnersByNumberOfSales");
	
	ThereAreRightsForInteraction = AccessRight("Read",Metadata.Documents.Meeting)
	                            And AccessRight("Read",Metadata.Documents.PhoneCall)
	                            And AccessRight("Read",Metadata.Documents.IncomingEmail)
	                            And AccessRight("Read",Metadata.Documents.OutgoingEmail)

EndProcedure

&AtClient
Function CurVersionOfSettings()
	
	Return 1;
	
EndFunction

&AtServer
Procedure GenerateReport()

	ReportTable.Clear();
	ObjectReport =  FormAttributeToValue("Report");
	
	ObjectReport.GenerateReport(ReportTable,StructureReportGenerationParameters());
	
EndProcedure

&AtClient
Function SelectionsAndSettingsAreFilledInIncorrectly()
	
	Cancel = False;
	
	ClearMessages();
	
	If (ReportGenerationPeriod.StartDate = Date(1,1,1) Or  ReportGenerationPeriod.EndDate = Date(1,1,1))
		And (AdditionalPeriodForAnalysis = "PreviousPeriod_" Or AdditionalPeriodForAnalysis = "LastYear") Then
		
		MessageText = NStr("vi = 'Trong trường hợp, mà có sử dụng kỳ bổ sung để phân tích, trong kỳ chính cần chỉ ra ngày bắt đầu và ngày kết thúc.';
							|ru = 'В случае, когда используется дополнительный период для анализа, у основного периода должны быть указаны дата начала и дата конца.';
							|en = 'When an extra period is used for analysis, specify end date and start date of the basic period.'; fa = 'When an extra period is used for analysis, specify end date and start date of the basic period.';
							|it = 'Nel caso si utilizzi un altro periodo aggiuntivo per l''analisi, nel periodo di base devono essere indicati la data di inizio e di fine.';
							|pl = 'W przypadku, gdy do analizy wykorzystywany jest dodatkowy okres, należy wskazać okres początkowy i końcowy dla okresu głównego.';
							|tr = 'Analiz için bir ek dönem kullanıldığında, ana dönemin bir başlangıç tarihi ve bir bitiş tarihi olmalıdır.'");
		CommonClientServer.MessageToUser(MessageText,,"ReportGenerationPeriod",,Cancel);
		
	EndIf;
	
	If Not DisplayCharts And Not DisplayTables Then
		
		MessageText = NStr("vi = 'Trong cài đặt để tạo báo cáo, trên tab ""Khác"", bạn phải chọn ít nhất một trong các chế độ đầu ra sau - bảng hoặc sơ đồ.';
							|ru = 'В настройках формирования отчета, на закладке ""Прочее"", необходимо выбрать хотя бы один из следующих режимов вывода - таблицы или диаграммы.';
							|en = 'Select at least one of the following output modes - tables or charts - in the report generation settings on the ""Other"" tab.'; fa = 'Select at least one of the following output modes - tables or charts - in the report generation settings on the ""Other"" tab.';
							|it = 'Nelle impostazioni di generazione del report, nella scheda ""Altro"", è necessario selezionare almeno una delle seguenti modalità di output: una tabella o un grafico.';
							|pl = 'W ustawieniach tworzenia raportu, na zakładce ""Inne"", należy wybrać co najmniej jeden z następujących trybów wyświetlania, czyli tabela lub wykres.';
							|tr = 'Rapor oluşturma ayarlarında, ""Diğer"" sekmesinde, aşağıdaki çıktı modlarından en az birini seçmelisiniz - tablolar veya diyagramlar.'");
		CommonClientServer.MessageToUser(MessageText,,"DisplayCharts",,Cancel);
		
	EndIf;
	
	If InterestRate = 0 Then
		
		MessageText = NStr("vi = 'Trong tùy chỉnh lập báo cáo, tại thẻ ""Phần khác"" cần chỉ ra phần trăm thuế suất để tính chi phí tài chính.';
							|ru = 'В настройках формирования отчета, на закладке ""Прочее"", необходимо указать процентную ставку для расчета финансовых потерь.';
							|en = 'Select an interest rate to calculate financial losses in the report generation settings on tab ""Other"".'; fa = 'Select an interest rate to calculate financial losses in the report generation settings on tab ""Other"".';
							|it = 'Nelle impostazioni di generazione del report, nella scheda ""Altro"", è necessario specificare il tasso di interesse per il calcolo delle perdite finanziarie.';
							|pl = 'W ustawieniach tworzenia raportu, na zakładce ""Inne"", należy podać stopę procentową do obliczania strat finansowych.';
							|tr = 'Rapor oluşturma ayarlarında, ""Diğer"" sekmesinde, mali kaybın hesaplanması için yüzde oranını belirtmeniz gerekir.'");
		CommonClientServer.MessageToUser(MessageText,,"InterestRate",,Cancel);
		
	EndIf;
	
	Return Cancel;
	
EndFunction

&AtServer
Procedure ProcessResultOnServer(AddressOfMetricsTree)
	
	ValueToFormData(GetFromTempStorage(AddressOfMetricsTree),SettingsTree);
	
EndProcedure

&AtServer
Function TemporaryStorageOfSettingsOnServer()
	
	Return PutToTempStorage(FormAttributeToValue("SettingsTree"),UUID);
	
EndFunction

&AtClient
Procedure FillDataSetTree()
	
	SettingsTree.GetItems().Clear();

	AddedRow = NewTreeItem(SettingsTree,"SalesProfitRevenue",NStr("vi = 'Bán hàng, lợi nhuận, doanh thu';
																	|ru = 'Продажи, прибыль, выручка';
																	|en = 'Sales, profit, revenue'; fa = 'Sales, profit, revenue';
																	|it = 'Vendite, utile, reddito';
																	|pl = 'Sprzedaże, zysk, przychód';
																	|tr = 'Satışlar, kâr, gelir'"),True);
	NewTreeItem(AddedRow,"Sales",NStr("vi = 'Bán hàng';
										|ru = 'Продажи';
										|en = 'Sales'; fa = 'فروش';
										|it = 'Vendite';
										|pl = 'Sales';
										|tr = 'Satışlar'"),True);
	NewTreeItem(AddedRow,"Profit_",NStr("vi = 'Lợi nhuận';
										|ru = 'Прибыль';
										|en = 'Profit'; fa = 'سود';
										|it = 'Utile';
										|pl = 'Profit';
										|tr = 'Kâr'"),True);
	NewTreeItem(AddedRow,"ReceiptOfCash",NStr("vi = 'Thu tiền';
												|ru = 'Поступление денежных средств';
												|en = 'Incoming payment'; fa = 'دریافت ورودی';
												|it = 'Flusso di cassa';
												|pl = 'Wpływ środków pieniężnych';
												|tr = 'Nakit girişi'"),True);
	NewTreeItem(AddedRow,"ReceiptOfDS_MinusCost",NStr("vi = 'Doanh thu (khi thanh toán) trừ giá vốn (khi giao hàng)';
														|ru = 'Выручка (по оплате) минус себестоимость (по отгрузке)';
														|en = 'Revenue (by payment) minus cost (by shipment)'; fa = 'Revenue (by payment) minus cost (by shipment)';
														|it = 'Entrate (pagamenti) meno costo (alla spedizione)';
														|pl = 'Przychód (przy płatności) minus koszt własny (przy wysyłce)';
														|tr = 'Gelir (ödemede) eksi satışların maliyeti (sevkiyatta)'"),True);
	
	AddedRow = NewTreeItem(SettingsTree,"ComplianceWithSalesConditions",NStr("vi = 'Tuân thủ điều kiện bán hàng';
																			|ru = 'Соблюдение условий продаж';
																			|en = 'Compliance with sales terms and conditions'; fa = 'Compliance with sales terms and conditions';
																			|it = 'Conformità con le condizioni di vendita';
																			|pl = 'Przestrzeganie warunków sprzedaży';
																			|tr = 'Satış koşullarına uygunluk'"),True);
	NewTreeItem(AddedRow,"LossesOverdueReceivables",NStr("vi = 'Thiệt hại do tăng thời hạn thanh toán nợ phải thu';
														|ru = 'Потери в результате превышения сроков погашения дебиторской задолженности';
														|en = 'Losses due to late receivables repayment'; fa = 'Losses due to late receivables repayment';
														|it = 'Perdite dovute al superamento della scadenza dei crediti';
														|pl = 'Straty z tytułu przekroczenia terminu zaległej spłaty wierzytelności';
														|tr = 'Vadesi geçmiş alacaklardan kaynaklanan zararlar'"),True);
	NewTreeItem(AddedRow,"ManualDiscountsAreProvided",NStr("vi = 'Chiết khấu thủ công được phép';
															|ru = 'Предоставленные ручные скидки';
															|en = 'Discount adjustments provided'; fa = 'Discount adjustments provided';
															|it = 'Sconti inseriti manualmente';
															|pl = 'Udzielenie rabaty ręczne';
															|tr = 'Gerçekleştirilen indirim düzeltmeleri'"),UseDiscountAdjustmentsInSales);
	
	AddedRow = NewTreeItem(SettingsTree,"WorkEfficiency",NStr("vi = 'Hiệu quả công việc';
																|ru = 'Эффективность работы';
																|en = 'Work efficiency'; fa = 'Work efficiency';
																|it = 'Efficienza di lavoro';
																|pl = 'Wydajność pracy';
																|tr = 'İş verimliliği'"),UseSalesOpportunitiesToCustomer Or UseInteraction);
	NewTreeItem(AddedRow,"EfficiencyOfOpportunityManagement",NStr("vi = 'Hiệu quả thực hiện vụ việc';
																	|ru = 'Эффективность ведения сделок';
																	|en = 'Efficiency of sales opportunity management'; fa = 'Efficiency of sales opportunity management';
																	|it = 'Efficienza conduzione degli accordi';
																	|pl = 'Skuteczność prowadzenia transakcji';
																	|tr = 'İşlem yönetiminin verimliliği'"),UseSalesOpportunitiesToCustomer);
	NewTreeItem(AddedRow,"InteractionEfficiency",NStr("vi = 'Hiểu quả giao tiếp';
														|ru = 'Эффективность взаимодействий';
														|en = 'Interaction efficiency'; fa = 'Interaction efficiency';
														|it = 'Efficienza nell''interazione';
														|pl = 'Skuteczność interakcji';
														|tr = 'Etkileşim verimliliği'"),UseInteraction And UseSalesOpportunitiesToCustomer);
	NewTreeItem(AddedRow,"SalesPerOpportunity",NStr("vi = 'Bán hàng trên một vụ việc';
													|ru = 'Продажи на одну сделку';
													|en = 'Sales per sales opportunity'; fa = 'Sales per sales opportunity';
													|it = 'Vendite per un accordo';
													|pl = 'Sprzedaż w jednej umowie';
													|tr = 'İşlem başına satışlar'"),UseSalesOpportunitiesToCustomer);
	NewTreeItem(AddedRow,"SalesPerOneInteraction",NStr("vi = 'Bán hàng trên một lần giao tiếp';
														|ru = 'Продажи на одно взаимодействие';
														|en = 'Sales per one interaction'; fa = 'Sales per one interaction';
														|it = 'Vendite per una interazione';
														|pl = 'Sprzedaż w jednej interakcji';
														|tr = 'Etkileşim başına satışlar'"),UseInteraction);
	
	AddedRow = NewTreeItem(SettingsTree,"ReasonsForLosses",NStr("vi = 'Nguyên nhân để mất khách hàng';
																|ru = 'Причины потерь';
																|en = 'Reasons for losses'; fa = 'Reasons for losses';
																|it = 'Cause perdita';
																|pl = 'Przyczyny utraty';
																|tr = 'Kayıp nedenleri'"),UseSalesOpportunitiesToCustomer Or RecordInitialRequest);
	NewTreeItem(AddedRow,"TheMainStagesOfLosses",NStr("vi = 'Các giai đoạn chính để mất khách hàng';
														|ru = 'Основные этапы потерь';
														|en = 'Main stages of losses'; fa = 'Main stages of losses';
														|it = 'Fasi di base di perdita';
														|pl = 'Główne etapy strat';
														|tr = 'Kaybın ana aşamaları'"),UseSalesOpportunitiesToCustomer);
	NewTreeItem(AddedRow,"ReasonsForLosingSalesOpportunities",NStr("vi = 'Nguyên nhân thất bại vụ việc';
																	|ru = 'Причины проигрыша сделок';
																	|en = 'Reasons for losing sales opportunities'; fa = 'دلایل از دست دادن فرصت‌های فروش';
																	|it = 'Cause perdita transazione';
																	|pl = 'Przyczyny niepowodzenia transakcji';
																	|tr = 'İşlem kaybetme nedenleri'"),UseSalesOpportunitiesToCustomer);
	NewTreeItem(AddedRow,"DissatisfactionWithPrimaryDemand",NStr("vi = 'Nguyên nhân không đảm bảo nhu cầu ban đầu';
																|ru = 'Причины неудовлетворения первичного спроса';
																|en = 'Reasons for primary demand non-fulfillment'; fa = 'دلایل عدم تأمین تقاضای اولیه';
																|it = 'Cause insoddisfazione domanda primaria';
																|pl = 'Przyczyny niezaspokojenia podstawowego popytu';
																|tr = 'Birincil talebin karşılanamama nedenleri'"),RecordInitialRequest);
	
	AddedRow = NewTreeItem(SettingsTree,"AttractingAndRetainingCustomers",NStr("vi = 'Thu hút và giữ chân khách hàng';
																				|ru = 'Привлечение и удержание клиентов';
																				|en = 'Attracting and retaining customers'; fa = 'Attracting and retaining customers';
																				|it = 'Attrazione e fidelizzazione dei clienti';
																				|pl = 'Przyciąganie i zatrzymanie klientów';
																				|tr = 'Müşterileri çekmek ve elde tutmak'"),PartnerClassificationIsUsed);
	NewTreeItem(AddedRow,"CustomerBaseTrends",NStr("vi = 'Biến động cơ sở khách hàng';
													|ru = 'Динамика клиентской базы';
													|en = 'Customer base trends'; fa = 'Customer base trends';
													|it = 'Dinamica della base clienti';
													|pl = 'Dynamika bazy klienckiej';
													|tr = 'Müşteri tabanının eğilimleri'"),PartnerClassificationIsUsed);
	NewTreeItem(AddedRow,"SalesToNewCustomers",NStr("vi = 'Bán hàng cho khách hàng mới';
													|ru = 'Продажи новым клиентам';
													|en = 'Sales to new customers'; fa = 'Sales to new customers';
													|it = 'Vendite a nuovi clienti';
													|pl = 'Sprzedaży na rzecz nowych klientów';
													|tr = 'Yeni müşterilere satışlar'"),PartnerClassificationIsUsed);
	
	AddedRow = NewTreeItem(SettingsTree,"CustomerLoyaltySupport",NStr("vi = 'Hỗ trợ khách hàng thân thiết';
																		|ru = 'Поддержка лояльности клиентов';
																		|en = 'Customer loyalty support'; fa = 'Customer loyalty support';
																		|it = 'Supporto alla fidelizzazione dei clienti';
																		|pl = 'Pomoc lojalności klientów';
																		|tr = 'Müşteri sadakatinin desteklenmesi'"),RecordCustomerClaims);
	NewTreeItem(AddedRow,"IncurredCustomerClaims",NStr("vi = 'Khiếu nại phát sinh của khách hàng';
														|ru = 'Возникшие претензии клиентов';
														|en = 'New customer complaints'; fa = 'New customer complaints';
														|it = 'Esposizioni reclami da parte dei clienti';
														|pl = 'Pojawiające się roszczenia klientów';
														|tr = 'Oluşan müşteri şikayetleri'"),RecordCustomerClaims);
	NewTreeItem(AddedRow,"ComplaintReasons",NStr("vi = 'Nguyên nhân phát sinh khiếu nại của khách hàng';
												|ru = 'Причины возникновения претензий клиентов';
												|en = 'Reasons for customer complaints'; fa = 'Reasons for customer complaints';
												|it = 'Cause esposizioni reclami da parte dei clienti';
												|pl = 'Przyczyny powstania roszczeń klientów';
												|tr = 'Müşteri şikayetlerinin nedenleri'"),RecordCustomerClaims);
	
EndProcedure

&AtClient
Procedure SetVisibilityOfIndicatorsDependingOnFO()
	
	StringProvidedManualDiscounts      = SettingsTree.GetItems()[1].GetItems()[1];
	HighWorkEfficiency              = SettingsTree.GetItems()[2];
	HighEfficiencyOfTransactions       = SettingsTree.GetItems()[2].GetItems()[0];
	HighEfficiencyOfInteractions      = SettingsTree.GetItems()[2].GetItems()[1];
	LineOfSalePerTransaction              = SettingsTree.GetItems()[2].GetItems()[2];
	SalesLinePerInteraction      = SettingsTree.GetItems()[2].GetItems()[3];
	StringCausesOfLosses                    = SettingsTree.GetItems()[3];
	LineMainStagesOfLosses              = SettingsTree.GetItems()[3].GetItems()[0];
	ReasonsForLosingTrades           = SettingsTree.GetItems()[3].GetItems()[1];
	LineDissatisfactionWithPrimaryDemand = SettingsTree.GetItems()[3].GetItems()[2];
	LineCustomerAcquisitionRetention     = SettingsTree.GetItems()[4];
	CustomerBaseDynamicsLine           = SettingsTree.GetItems()[4].GetItems()[0];
	SalesLineToNewCustomers             = SettingsTree.GetItems()[4].GetItems()[1];
	CustomerLoyaltySupportLine      = SettingsTree.GetItems()[5];
	AllCustomerClaimsThatHaveArisen       = SettingsTree.GetItems()[5].GetItems()[0];
	LineReasonsForClaims    = SettingsTree.GetItems()[5].GetItems()[1];
	
	StringProvidedManualDiscounts.AvailabilityAccordingToFS = UseDiscountAdjustmentsInSales;
	HighWorkEfficiency.AvailabilityAccordingToFS = (UseSalesOpportunitiesToCustomer Or UseInteraction);
	HighEfficiencyOfTransactions.AvailabilityAccordingToFS = UseSalesOpportunitiesToCustomer;
	HighEfficiencyOfInteractions.AvailabilityAccordingToFS = (UseSalesOpportunitiesToCustomer And UseInteraction And ThereAreRightsForInteraction);
	LineOfSalePerTransaction.AvailabilityAccordingToFS = UseSalesOpportunitiesToCustomer;
	SalesLinePerInteraction.AvailabilityAccordingToFS = UseInteraction And ThereAreRightsForInteraction;
	StringCausesOfLosses.AvailabilityAccordingToFS = (UseSalesOpportunitiesToCustomer Or RecordInitialRequest);
	LineMainStagesOfLosses.AvailabilityAccordingToFS = UseSalesOpportunitiesToCustomer;
	ReasonsForLosingTrades.AvailabilityAccordingToFS = UseSalesOpportunitiesToCustomer;
	LineDissatisfactionWithPrimaryDemand.AvailabilityAccordingToFS = RecordInitialRequest;
	LineCustomerAcquisitionRetention.AvailabilityAccordingToFS = PartnerClassificationIsUsed;
	CustomerBaseDynamicsLine.AvailabilityAccordingToFS = PartnerClassificationIsUsed;
	SalesLineToNewCustomers.AvailabilityAccordingToFS = PartnerClassificationIsUsed;
	CustomerLoyaltySupportLine.AvailabilityAccordingToFS = RecordCustomerClaims;
	AllCustomerClaimsThatHaveArisen.AvailabilityAccordingToFS = RecordCustomerClaims;
	LineReasonsForClaims.AvailabilityAccordingToFS = RecordCustomerClaims;
	
	If Not UseDiscountAdjustmentsInSales Then
		StringProvidedManualDiscounts.Include = False;
	EndIf;
	
	If Not (UseSalesOpportunitiesToCustomer Or UseInteraction) Then
		HighWorkEfficiency.Include = 0;
	EndIf;
	
	If Not (UseSalesOpportunitiesToCustomer And UseInteraction) Or (Not ThereAreRightsForInteraction) Then
		HighEfficiencyOfInteractions.Include = False;
	EndIf;
	
	If Not UseSalesOpportunitiesToCustomer Then
		HighEfficiencyOfTransactions.Include = False;
		LineOfSalePerTransaction.Include = False;
		LineMainStagesOfLosses.Include = False;
		ReasonsForLosingTrades.Include = False;
		ReasonsForLosingTrades.Include = False;
	EndIf;
	
	If Not UseInteraction Or (Not ThereAreRightsForInteraction) Then
		SalesLinePerInteraction.Include = False;
	EndIf;
	
	If Not (UseSalesOpportunitiesToCustomer Or RecordInitialRequest) Then
		LineDissatisfactionWithPrimaryDemand.Include = 0;
	EndIf;
	
	If Not RecordInitialRequest Then
		StringCausesOfLosses.Include = 0;
	EndIf;
	
	If Not RecordCustomerClaims Then
		CustomerLoyaltySupportLine.Include = False;
		AllCustomerClaimsThatHaveArisen.Include = False;
		LineReasonsForClaims.Include = False;
	EndIf;
	
EndProcedure

&AtClient
Function NewTreeItem(Parent,Name,Description,AvailabilityByFederalDistrict)
	
	NewRow = Parent.GetItems().Add();
	NewRow.Name = Name;
	NewRow.Description = Description;
	NewRow.Include = AvailabilityByFederalDistrict;
	NewRow.AvailabilityAccordingToFS = AvailabilityByFederalDistrict;
	
	Return NewRow;
	
EndFunction

&AtServer
Function StructureOfSettingsForm()

	ParametersForSettingsForm = New Structure();
	ParametersForSettingsForm.Insert("SettingsTree",TemporaryStorageOfSettingsOnServer());
	ParametersForSettingsForm.Insert("DisplayCharts",DisplayCharts);
	ParametersForSettingsForm.Insert("DisplayTables",DisplayTables);
	ParametersForSettingsForm.Insert("DisplayLegend",DisplayLegend);
	ParametersForSettingsForm.Insert("InterestRate",InterestRate);
	ParametersForSettingsForm.Insert("CompositionSetup",Report.SettingsComposer);
	ParametersForSettingsForm.Insert("UID_OfCallingForm",UUID);
	
	Return  ParametersForSettingsForm;

EndFunction

#EndRegion
