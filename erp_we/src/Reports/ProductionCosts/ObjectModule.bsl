
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
// Parameters:
//	Context							- Arbitrary								- parameters of the context in which the report is used.
//	SchemaKey							- String									- ID of the current configuration Builder schema.
//	VariantKey						- String									- name of the predefined or unique ID of the custom
//																						version of the report.
//										- Undefined 								- a call for a decryption option or without context.
//	NewDCSettings					- DataCompositionSettings					- report variant settings that will be loaded
//																						into the settings Builder after it is initialized.
//										- Undefined 								- the option settings do not need to be downloaded (already downloaded earlier).
//	NewDCUserSettings	- DataCompositionUserSettings - custom settings that will be loaded into
//																						the settings Builder after it is initialized.
//										- Undefined 								- user settings do not need to be downloaded (already downloaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		
		If NewDCUserSettings = Undefined Then
			UserSettings = Context.Report.SettingsComposer.UserSettings; // DataCompositionUserSettings -
			ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, UserSettings);
		Else
			ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
		EndIf;
		
		ConfigureSelectionParametersByFunctionalOptions(NewDCSettings);
		
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionProcessor = New DataCompositionProcessor;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	ReportSettings.DataParameters.SetParameterValue("UsedMaterials",
		NStr("vi = 'Nguyên vật liệu';
			|ru = 'Материалы';
			|en = 'Materials'; fa = 'مواد';
			|it = 'Materiali';
			|pl = 'Materials';
			|tr = 'Malzemeler'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedFromWarehouse",
		NStr("vi = 'Đã tiếp nhận từ kho hoặc các phân xưởng khác và nhập thông qua điều chuyển';
			|ru = 'Поступило со склада или кладовых других цехов и приходы по перемещениям';
			|en = 'Received from warehouse or other shop floor storerooms and transfer receipts'; fa = 'Received from warehouse or other shop floor storerooms and transfer receipts';
			|it = 'Ricevuto dal magazzino o da magazzini di altre imprese ed entrate per spostamento';
			|pl = 'Wpłynęło z magazynu lub spiżarni innych wytwórni i przychody według przeniesień';
			|tr = 'Diğer üretim atölyesi depolarından veya ambarlarından ve hareketlere göre alındı'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedGNZP",
		NStr("vi = 'Đã tiếp nhận từ kho vào sản xuất dở dang';
			|ru = 'Поступило со склада в незавершенное производство';
			|en = 'Received from warehouse to work-in-progress'; fa = 'Received from warehouse to work-in-progress';
			|it = 'Ricevuto dal magazzino per la produzione non ultimata';
			|pl = 'Wpłynęło z magazynu do niezakończonej produkcji';
			|tr = 'Ambardan devam eden imalata alındı'"));
	ReportSettings.DataParameters.SetParameterValue("Expenses",
		NStr("vi = 'Xuất thông qua điều chuyển, chuyển giao sang kho, các phân xưởng khác, vào sản xuất';
			|ru = 'Расходы по перемещениям, передачи на склад, в другие кладовые, в производство';
			|en = 'Expenses for transfers, transfers to a warehouse, other storerooms, production'; fa = 'Expenses for transfers, transfers to a warehouse, other storerooms, production';
			|it = 'Spese per spostamenti, trasferimenti a magazzini, in altri magazzini, alla produzione';
			|pl = 'Rozchody według przemieszczeń, przeniesienia do magazynu. do innych spiżarni, do produkcji';
			|tr = 'Ambara, diğer depolara, üretime yapılan transferlerin nakil giderleri'"));
	ReportSettings.DataParameters.SetParameterValue("WriteOffsForExpenses",
		NStr("vi = 'Ghi giảm vào chi phí';
			|ru = 'Списания на расходы';
			|en = 'Written off as expenses'; fa = 'اسقاط‌شده به‌عنوان هزینه';
			|it = 'Storno per le spese';
			|pl = 'Spisanie na rozchody';
			|tr = 'Giderlere yazılması'"));
	ReportSettings.DataParameters.SetParameterValue("ParishesFromPostashchikov",
		NStr("vi = 'Nhập từ nhà cung cấp và xuất xưởng thành phẩm';
			|ru = 'Приходы от поставщика и выпуски продукции';
			|en = 'Receipts from vendor and manufactured product releases'; fa = 'Receipts from vendor and manufactured product releases';
			|it = 'Entrate dal fornitore e avvio di produzione';
			|pl = 'Przychody od dostawców i wydania produkcji';
			|tr = 'Satıcıdan gelenler ve imal edilen ürün çıkışları'"));
	
	ReportSettings.DataParameters.SetParameterValue("Itemized",
		NStr("vi = 'Mục hàng';
			|ru = 'Постатейные';
			|en = 'Itemized'; fa = 'تفکیک‌شده';
			|it = 'Dettagliati per voce';
			|pl = 'Itemized';
			|tr = 'Ayrıntılı'"));
	ReportSettings.DataParameters.SetParameterValue("OpeningBalance",
		NStr("vi = 'Dư đầu';
			|ru = 'Начальный остаток';
			|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
			|it = 'Saldo iniziale';
			|pl = 'Saldo początkowe';
			|tr = 'Açılış bakiyesi'"));
	ReportSettings.DataParameters.SetParameterValue("Registration",
		NStr("vi = 'Mua dịch vụ, đăng ký, phản ánh tiền lương';
			|ru = 'Закупка услуг, регистрация, отражение зарплаты';
			|en = 'Service purchase, registration, payroll'; fa = 'Service purchase, registration, payroll';
			|it = 'Acquisto servizi, registrazione, visualizzazione stipendio';
			|pl = 'Zakup usług, rejestracja, wyświetlenie wynagrodzenia';
			|tr = 'Hizmet satın alımı, kayıt, bordro yansıması'"));
	ReportSettings.DataParameters.SetParameterValue("DistributionToProduction",
		NStr("vi = 'Phân bổ cho sản xuất';
			|ru = 'Распределение на производство';
			|en = 'Allocation to production'; fa = 'تسهیم به تولید';
			|it = 'Distribuzione in produzione';
			|pl = 'Przydzielenie do produkcji';
			|tr = 'Üretime dağıtım'"));
	ReportSettings.DataParameters.SetParameterValue("Disposal",
		NStr("vi = 'Ghi giảm vào chi phí khác, thanh lý';
			|ru = 'Списание на другие статьи, выбытие';
			|en = 'Write off to other items, retirement'; fa = 'Write off to other items, retirement';
			|it = 'Cancellazione in altre voci, uscita';
			|pl = 'Rozchód na inne pozycje, wyksięgowanie';
			|tr = 'Diğer kalemlere gider yazma, çekilme'"));
	ReportSettings.DataParameters.SetParameterValue("Transfer",
		NStr("vi = 'Chuyển sang đối tượng phát sinh chi phí khác';
			|ru = 'Перенос на другой объект возникновения затрат';
			|en = 'Allocate to another cost center'; fa = 'Allocate to another cost center';
			|it = 'Trasferimento a un altro oggetto di costo';
			|pl = 'Przeniesienie na inny obiekt tworzenia się rozchodów';
			|tr = 'Başka bir gider oluşumun nesnesine aktarım'"));
	ReportSettings.DataParameters.SetParameterValue("ClosingBalance",
		NStr("vi = 'Dư cuối';
			|ru = 'Конечный остаток';
			|en = 'Closing balance'; fa = 'مانده پایان دوره';
			|it = 'Saldo finale';
			|pl = 'Saldo końcowe';
			|tr = 'Kapanış bakiyesi'"));
		
	ReportSettings.DataParameters.SetParameterValue("Production",
		NStr("vi = 'Sản xuất';
			|ru = 'Производство';
			|en = 'Production'; fa = 'تولید';
			|it = 'Produzione';
			|pl = 'Production';
			|tr = 'Üretim'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedMaterials22",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (nguyên vật liệu) dành cho 2.2';
			|ru = 'Поступило на незавершенное производство (материалы) для 2.2';
			|en = 'Received to work-in-progress (materials) 2.2'; fa = 'Received to work-in-progress (materials) 2.2';
			|it = 'Verificatosi nella produzione non ultimata (materiali) per 2.2';
			|pl = 'Wpłynęło do produkcji niezakończonej (materiały) dla 2.2';
			|tr = 'Devam eden imalata alındı (malzemeler) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedMaterials21",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (nguyên vật liệu) dành cho 2.1';
			|ru = 'Поступило на незавершенное производство (материалы) для 2.1';
			|en = 'Received to work-in-progress (materials) 2.1'; fa = 'Received to work-in-progress (materials) 2.1';
			|it = 'Verificatosi nella produzione non ultimata (materiali) per 2.1';
			|pl = 'Wpłynęło do produkcji niezakończonej (materiały) dla 2.1';
			|tr = 'Devam eden imalata alındı (malzemeler) 2.1'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedWaste",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (phế liệu theo giá trị cố định)';
			|ru = 'Поступило на незавершенное производство (отходы по фиксированной стоимости)';
			|en = 'Received to work-in-progress (waste at a fixed cost)'; fa = 'Received to work-in-progress (waste at a fixed cost)';
			|it = 'Verificatosi nella produzione non ultimata (scarti a costo fisso)';
			|pl = 'Wpłynęło do niezakończonej produkcji (odpady według stałej ceny)';
			|tr = 'Devam eden imalata alındı (sabit maliyete göre atıklar)'"));
	ReportSettings.DataParameters.SetParameterValue("ServicesReceived22",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (dịch vụ của người nhận gia công) dành cho 2.2';
			|ru = 'Поступило на незавершенное производство (услуги переработчика) для 2.2';
			|en = 'Received to work-in-progress (subcontractor services) 2.2'; fa = 'Received to work-in-progress (subcontractor services) 2.2';
			|it = 'Verificatosi nella produzione non ultimata (servizi elaboratore) per 2.2';
			|pl = 'Wpłynęło do niezakończonej produkcji (usługi przetwórcy) dla 2.2';
			|tr = 'Devam eden imalata alındı (fason hizmetleri) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("Expense22",
		NStr("vi = 'Chi phí từ sản xuất dở dang (nguyên vật liệu) dành cho 2.2';
			|ru = 'Расход из незавершенного производства (материалы) для 2.2';
			|en = 'Work-in-progress expense (materials) 2.2'; fa = 'Work-in-progress expense (materials) 2.2';
			|it = 'Spese della produzione non ultimata (materiali) per 2.2';
			|pl = 'Rozchód z niezakończonej produkcji (materiały) dla 2.2';
			|tr = 'Devam eden imalat gideri (malzemeler) 2.2'"));	
	ReportSettings.DataParameters.SetParameterValue("Expense21",
		NStr("vi = 'Chi phí từ sản xuất dở dang (nguyên vật liệu) dành cho 2.1';
			|ru = 'Расход из незавершенного производства (материалы) для 2.1';
			|en = 'Work-in-progress expense (materials) 2.1'; fa = 'Work-in-progress expense (materials) 2.1';
			|it = 'Spese della produzione non ultimata (materiali) per 2.1';
			|pl = 'Rozchód z niezakończonej produkcji (materiały) dla 2.1';
			|tr = 'Devam eden imalat gideri (malzemeler) 2.1'"));
		
	ReportSettings.DataParameters.SetParameterValue("InitialBalanceLaborCosts22",
		NStr("vi = 'Dư đầu (công lao động) dành cho 2.2';
			|ru = 'Начальный остаток (трудозатраты) для 2.2';
			|en = 'Opening balance (labor costs) 2.2'; fa = 'Opening balance (labor costs) 2.2';
			|it = 'Saldo iniziale (costi del lavoro) per 2.2';
			|pl = 'Saldo początkowe (nakłady pracy) dla 2.2';
			|tr = '2.2 için açılış bakiyesi (iş gücü maliyetleri)'"));
	ReportSettings.DataParameters.SetParameterValue("InitialBalanceLaborCosts21",
		NStr("vi = 'Dư đầu (công lao động) dành cho 2.1';
			|ru = 'Начальный остаток (трудозатраты) для 2.1';
			|en = 'Opening balance (labor costs) 2.1'; fa = 'Opening balance (labor costs) 2.1';
			|it = 'Saldo iniziale (costi del lavoro) per 2.1';
			|pl = 'Saldo początkowe (nakłady pracy) dla 2.1';
			|tr = '2.1 için açılış bakiyesi (iş gücü maliyetleri)'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedLaborCosts22",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (công lao động) dành cho 2.2';
			|ru = 'Поступило на незавершенное производство (трудозатраты) для 2.2';
			|en = 'Received to work-in-progress (labor costs) 2.2'; fa = 'Received to work-in-progress (labor costs) 2.2';
			|it = 'Verificatosi nella produzione non ultimata (costi del lavoro) per 2.2';
			|pl = 'Wpłynęło do produkcji niezakończonej (nakłady pracy) dla 2.2';
			|tr = 'Devam eden imalata alındı (iş gücü maliyetleri) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedLaborCosts21",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (công lao động) dành cho 2.1';
			|ru = 'Поступило на незавершенное производство (трудозатраты) для 2.1';
			|en = 'Received to work-in-progress (labor costs) 2.1'; fa = 'Received to work-in-progress (labor costs) 2.1';
			|it = 'Verificatosi nella produzione non ultimata (costi del lavoro) per 2.1';
			|pl = 'Wpłynęło do produkcji niezakończonej (nakłady pracy) dla 2.1';
			|tr = 'Devam eden imalata alındı (iş gücü maliyetleri) 2.1 '"));
	ReportSettings.DataParameters.SetParameterValue("ConsumptionLaborCosts22",
		NStr("vi = 'Chi phí từ sản xuất dở dang (công lao động) dành cho 2.2';
			|ru = 'Расход из незавершенного производства (трудозатраты) для 2.2';
			|en = 'Work-in-progress expense (labor costs) 2.2'; fa = 'Work-in-progress expense (labor costs) 2.2';
			|it = 'Spese della produzione non ultimata (costi del lavoro) per 2.2';
			|pl = 'Rozchód z niezakończonej produkcji (nakłady pracy) dla 2.2';
			|tr = 'Devam eden imalat gideri (iş gücü maliyetleri) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("ConsumptionLaborCosts21",
		NStr("vi = 'Chi phí từ sản xuất dở dang (công lao động) dành cho 2.1';
			|ru = 'Расход из незавершенного производства (трудозатраты) для 2.1';
			|en = 'Work-in-progress expense (labor costs) 2.1'; fa = 'Work-in-progress expense (labor costs) 2.1';
			|it = 'Spese della produzione non ultimata (costi del lavoro) per 2.1';
			|pl = 'Rozchód z niezakończonej produkcji (nakłady pracy) dla 2.1';
			|tr = 'Devam eden imalat gideri (iş gücü maliyetleri) 2.1'"));
	ReportSettings.DataParameters.SetParameterValue("FinalBalanceLaborCosts22",
		NStr("vi = 'Dư cuối (công lao động) dành cho 2.2';
			|ru = 'Конечный остаток (трудозатраты) для 2.2';
			|en = 'Closing balance (labor costs) 2.2'; fa = 'Closing balance (labor costs) 2.2';
			|it = 'Bilancio finale (costi del lavoro) per 2.2';
			|pl = 'Saldo końcowe (nakłady pracy) dla 2.2';
			|tr = '2.2 için kapanış bakiyesi (iş gücü maliyetleri)'"));
	ReportSettings.DataParameters.SetParameterValue("FinalBalanceLaborCosts21",
		NStr("vi = 'Dư cuối (công lao động) dành cho 2.1';
			|ru = 'Конечный остаток (трудозатраты) для 2.1';
			|en = 'Closing balance (labor costs) 2.1'; fa = 'Closing balance (labor costs) 2.1';
			|it = 'Bilancio finale (costi del lavoro) per 2.1';
			|pl = 'Saldo końcowe (nakłady pracy) dla 2.1';
			|tr = '2.1 için kapanış bakiyesi (iş gücü maliyetleri)'"));
		
	ReportSettings.DataParameters.SetParameterValue("InitialRemainderArticleByArticle22",
		NStr("vi = 'Dư đầu (mục hàng) dành cho 2.2';
			|ru = 'Начальный остаток (постатейные) для 2.2';
			|en = 'Opening balance (itemized) 2.2'; fa = 'Opening balance (itemized) 2.2';
			|it = 'Saldo iniziale (per articoli) per 2.2';
			|pl = 'Saldo początkowe (według pozycji) 2.2';
			|tr = '2.2 için açılış bakiyesi (ayrıntılı)'"));
	ReportSettings.DataParameters.SetParameterValue("InitialRemainderArticleByArticle21",
		NStr("vi = 'Dư đầu (mục hàng) dành cho 2.1';
			|ru = 'Начальный остаток (постатейные) для 2.1';
			|en = 'Opening balance (itemized) 2.1'; fa = 'Opening balance (itemized) 2.1';
			|it = 'Saldo iniziale (per articoli) per 2.1';
			|pl = 'Saldo początkowe (według pozycji) dla 2.1';
			|tr = '2.1 için açılış bakiyesi (ayrıntılı)'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedArticleByArticle22",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (mục hàng) dành cho 2.2';
			|ru = 'Поступило на незавершенное производство (постатейные) для 2.2';
			|en = 'Received to work-in-progress (itemized) 2.2'; fa = 'Received to work-in-progress (itemized) 2.2';
			|it = 'Verificatosi nella produzione non ultimata (per articoli) per 2.2';
			|pl = 'Wpłynęło do produkcji niezakończonej (według pozycji) dla 2.2';
			|tr = 'Devam eden imalata alındı (ayrıntılı) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedArticleByArticle21",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (mục hàng) dành cho 2.1';
			|ru = 'Поступило на незавершенное производство (постатейные) для 2.1';
			|en = 'Received to work-in-progress (itemized) 2.1'; fa = 'Received to work-in-progress (itemized) 2.1';
			|it = 'Verificatosi nella produzione non ultimata (per articoli) per 2.1';
			|pl = 'Wpłynęło do produkcji niezakończonej (według pozycji) dla 2.1';
			|tr = 'Devam eden imalata alındı (ayrıntılı) 2.1'"));
	ReportSettings.DataParameters.SetParameterValue("ConsumptionArticleByArticle22",
		NStr("vi = 'Chi phí từ sản xuất dở dang (mục hàng) dành cho 2.2';
			|ru = 'Расход из незавершенного производства (постатейные) для 2.2';
			|en = 'Work-in-progress expense (itemized) 2.2'; fa = 'Work-in-progress expense (itemized) 2.2';
			|it = 'Spese della produzione non ultimata (per articoli) per 2.2';
			|pl = 'Rozchód z niezakończonej produkcji (według pozycji) dla 2.2';
			|tr = 'Devam eden imalat gideri (ayrıntılı) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("ConsumptionArticleByArticle21",
		NStr("vi = 'Chi phí từ sản xuất dở dang (mục hàng) dành cho 2.1';
			|ru = 'Расход из незавершенного производства (постатейные) для 2.1';
			|en = 'Work-in-progress expense (itemized) 2.1'; fa = 'Work-in-progress expense (itemized) 2.1';
			|it = 'Spese della produzione non ultimata (per articoli) per 2.1';
			|pl = 'Rozchód z niezakończonej produkcji (według pozycji) dla 2.1';
			|tr = 'Devam eden imalat gideri (ayrıntılı) 2.1'"));
	ReportSettings.DataParameters.SetParameterValue("FinalRemainderArticleByArticle22",
		NStr("vi = 'Dư cuối (công lao động) dành cho 2.2';
			|ru = 'Конечный остаток (трудозатраты) для 2.2';
			|en = 'Closing balance (labor costs) 2.2'; fa = 'Closing balance (labor costs) 2.2';
			|it = 'Bilancio finale (costi del lavoro) per 2.2';
			|pl = 'Saldo końcowe (nakłady pracy) dla 2.2';
			|tr = '2.2 için kapanış bakiyesi (iş gücü maliyetleri)'"));
	ReportSettings.DataParameters.SetParameterValue("FinalRemainderArticleByArticle21",
		NStr("vi = 'Dư cuối (công lao động) dành cho 2.1';
			|ru = 'Конечный остаток (трудозатраты) для 2.1';
			|en = 'Closing balance (labor costs) 2.1'; fa = 'Closing balance (labor costs) 2.1';
			|it = 'Bilancio finale (costi del lavoro) per 2.1';
			|pl = 'Saldo końcowe (nakłady pracy) dla 2.1';
			|tr = '2.1 için kapanış bakiyesi (iş gücü maliyetleri)'"));
		
	ReportSettings.DataParameters.SetParameterValue("Material_",
		NStr("vi = 'Nguyên vật liệu';
			|ru = 'Материальные';
			|en = 'Material'; fa = 'ماده';
			|it = 'Materiali';
			|pl = 'Material';
			|tr = 'Malzeme'"));
	ReportSettings.DataParameters.SetParameterValue("Services",
		NStr("vi = 'Dịch vụ';
			|ru = 'Услуги';
			|en = 'Services'; fa = 'خدمات';
			|it = 'Servizi';
			|pl = 'Services';
			|tr = 'Hizmetler'"));
	ReportSettings.DataParameters.SetParameterValue("LaborCosts",
		NStr("vi = 'Công lao động';
			|ru = 'Трудозатраты';
			|en = 'Labor costs'; fa = 'هزینه‌های دستمزد';
			|it = 'Costi di manodopera';
			|pl = 'Nakłady pracy';
			|tr = 'İş gücü maliyetleri'"));
	
	ReportSettings.DataParameters.SetParameterValue("InclusionExclusionOfVAT",
		NStr("vi = 'Gồm/không gồm thuế GTGT';
			|ru = 'Вкл./искл. НДС';
			|en = 'Include/exclude VAT'; fa = 'شامل/بدون VAT';
			|it = 'IVA incl./escl.';
			|pl = 'Brutto/netto';
			|tr = 'KDV dahil/hariç'"));
	
	ReportPeriodParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Period");
	ReportPeriodParameterValue = ReportPeriodParameter.Value; //StandardPeriod
	WithoutFilterByPeriod = Not ReportPeriodParameter.Use;
	DataCompositionClientServer.SetParameter(ReportSettings, "WithoutFilterByPeriod", WithoutFilterByPeriod);

	NoSelectionByStartPeriod = WithoutFilterByPeriod Or Not ValueIsFilled(ReportPeriodParameterValue.StartDate);
	DataCompositionClientServer.SetParameter(ReportSettings, "NoSelectionByStartPeriod", NoSelectionByStartPeriod);
	
	MainDataSet = DataCompositionSchema.DataSets.Main; // DataCompositionSchemaDataSetUnion
	RecruitmentRequests = MainDataSet.Items;
	
	InventoryRequest = CostsServer.QueryTextProductionMaterialCost();
	RecruitmentRequests.Inventory.Query = InventoryRequest.QueryText;
	
	RequestArticleByArticle = CostsServer.QueryTextItemizedProductionCosts();
	RecruitmentRequests.Itemized.Query = RequestArticleByArticle.QueryText;
	
	BatchRequest = CostsServer.QueryTextProductionCostsByProductionLots();
	RecruitmentRequests.ProductionLots.Query = BatchRequest.QueryText;
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	MainDataSet = CompositionTemplate.DataSets.Main; // DataCompositionSchemaDataSetUnion
	RecruitmentRequests = MainDataSet.Items;

	CostsServer.AddSelectionForSelectedResources(InventoryRequest.Resources, RecruitmentRequests.Inventory);
	CostsServer.AddSelectionForSelectedResources(RequestArticleByArticle.Resources, RecruitmentRequests.Itemized);
	CostsServer.AddSelectionForSelectedResources(BatchRequest.Resources, RecruitmentRequests.ProductionLots);
	
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True, False);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

// Adjusts the available values for the "cost Data" data layout parameter, depending on the option.
// 
// Parameters:
//	Document - Document Link.Distribution of labor costs - a decoding document.
//	NewDCSettings - DataCompositionSettings - overriding the report settings.
//	NewDCUserSettings - DataCompositionUserSettings - data layout scheme settings.
Procedure ConfigureReportParametersByReportVariant(ReportSettings, NewDCSettings, NewDCUserSettings)
	
	PredefinedOption = GetPredefinedOption(ReportSettings.OptionRef);
	
	ReportDataParameter = DataCompositionSchema.Parameters.Find("Cost_Data");
	EnterpriseParameter = DataCompositionSchema.Parameters.Find("ByEnterprise");
	
	ChoiceList = New ValueList;
	
	If PredefinedOption.VariantKey = "MovementOfTMQiProductionCostsForEnterprise" Then
		
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
								|ru = 'В валюте упр. учета с НДС';
								|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale con IVA';
								|pl = 'W walucie zarz. ewidencji z VAT';
								|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán quản trị không gồm thuế GTGT';
								|ru = 'В валюте упр. учета без НДС';
								|en = 'In management accounting currency, excluding VAT'; fa = 'به ارز حسابداری مدیریت، بدون مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale senza IVA';
								|pl = 'W walucie zarz. ewidencji bez VAT';
								|tr = 'KDV hariç yönetim muhasebesi para birimi cinsinden'"));
		EnterpriseParameter.Value = True;
		
	Else
		
		If CalculationOfCostCached.CompanyManagementAccounting() Then
			ChoiceList.Add(3, NStr("vi = 'Theo tiền tệ kế toán quản trị';
									|ru = 'В валюте упр. учета';
									|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
									|it = 'In valuta della contabilità gestionale';
									|pl = 'W walucie ewidencji zarządczej';
									|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
		EndIf;
		ChoiceList.Add(4, NStr("vi = 'Bằng tiền tệ kế toán pháp quy';
								|ru = 'В валюте регл. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'In valuta della contabilità regolamentata';
								|pl = 'W walucie ewidencji reglamentowanej';
								|tr = 'Yerel muhasebe para birimi cinsinden'"));
		EnterpriseParameter.Value = False;
		
	EndIf;
	
	ReportDataParameter.SetAvailableValues(ChoiceList);
	
	If NewDCSettings = Undefined
		Or NewDCUserSettings = Undefined Then
		Return;
	EndIf;
	
	ValueOfReportDataParameter = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Cost_Data"));
	ConfiguringReportData = NewDCUserSettings.Items.Find(ValueOfReportDataParameter.UserSettingID);
	
	If Not ConfiguringReportData = Undefined
		And ChoiceList.FindByValue(ConfiguringReportData.Value) = Undefined Then
		ConfiguringReportData.Value = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

Function GetPredefinedOption(Val Variant)
	
	OptionsKeys = New Array;
	OptionsKeys.Add("TMChiMovementProductionCosts");
	OptionsKeys.Add("MovementOfTMQiProductionCostsForEnterprise");
	
	// If the option is not specified, then we will take the first one from the default list
	If Variant = Undefined Then
		Return New Structure("VariantKey", OptionsKeys[0]);
	EndIf;
	
	While OptionsKeys.Find(Variant.VariantKey) = Undefined
		And ValueIsFilled(Variant.Parent) Do
		Variant = Variant.Parent;
	EndDo;
	
	Return Variant;
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("ComplexAutomation") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "ProductionOrder");
	EndIf;
	
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False; 
	If Not CalculationOfPermanentAndTemporaryDifferencesIsKept Then
		FieldsToDelete__ = New Array;
		FieldsToDelete__.Add("InitialBalanceIsTA");
		FieldsToDelete__.Add("InitialBalanceOfTD");
		FieldsToDelete__.Add("InitialBalanceOfPD");
		FieldsToDelete__.Add("PurchasedWELL");
		FieldsToDelete__.Add("AcquiredByTD");
		FieldsToDelete__.Add("PurchasedPD");
		FieldsToDelete__.Add("ReceivedTA");
		FieldsToDelete__.Add("TDHasBeenReceived");
		FieldsToDelete__.Add("ReceivedPD");
		FieldsToDelete__.Add("MovingTA");
		FieldsToDelete__.Add("TDMovements");
		FieldsToDelete__.Add("PDMovements");
		FieldsToDelete__.Add("WrittenOffTA");
		FieldsToDelete__.Add("TDWasWrittenOff");
		FieldsToDelete__.Add("WrittenOffPD");
		FieldsToDelete__.Add("PassedTA");
		FieldsToDelete__.Add("SubmittedByTD");
		FieldsToDelete__.Add("SubmittedByPD");
		FieldsToDelete__.Add("OtherWriteOffsWELL");
		FieldsToDelete__.Add("OtherWriteOffsOfTD");
		FieldsToDelete__.Add("OtherWriteOffOfPD");
		FieldsToDelete__.Add("SpentOnProductionOfTA");
		FieldsToDelete__.Add("SpentOnProductionOfTD");
		FieldsToDelete__.Add("SpentOnProductionOfPD");
		FieldsToDelete__.Add("ProducedByTA");
		FieldsToDelete__.Add("ProducedByTD");
		FieldsToDelete__.Add("ProducedByPD");
		FieldsToDelete__.Add("TransitBetweenOVZNU");
		FieldsToDelete__.Add("TransitBetweenHIA_");
		FieldsToDelete__.Add("TransitBetweenOVZPR");
		FieldsToDelete__.Add("ProductionCostsTA");
		FieldsToDelete__.Add("CostOfProductionOfTD");
		FieldsToDelete__.Add("CostOfProductionPD");
		FieldsToDelete__.Add("FinalBalanceIsTA");
		FieldsToDelete__.Add("FinalBalanceOfTD");
		FieldsToDelete__.Add("FinalBalanceOfPD");
		
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldsToDelete__, DataCompositionSchema,
			SettingsComposer, "", True);
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, FieldsToDelete__);
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, FieldsToDelete__, True);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf