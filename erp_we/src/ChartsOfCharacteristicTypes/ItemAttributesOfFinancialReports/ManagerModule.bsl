#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set of details
//                                 of the plan and types of characteristics.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	DefaultLanguageCode = Common.DefaultLanguageCode();

	#Region Currency
	Item = Items.Add();
	Item.PredefinedDataName = "Currency";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Currencies"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Tiền tệ';
							|ru = 'Валюта';
							|en = 'Currency'; fa = 'ارز';
							|it = 'Valuta';
							|pl = 'Currency';
							|tr = 'Para birimi'", DefaultLanguageCode);
	#EndRegion

	#Region UpperBoundOfData
	Item = Items.Add();
	Item.PredefinedDataName = "UpperBoundOfData";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Giới hạn trên của dữ liệu';
							|ru = 'Верхняя граница данных';
							|en = 'Upper bound of data'; fa = 'حد بالای داده';
							|it = 'Limite superiore dei dati';
							|pl = 'Górna granica danych';
							|tr = 'Üst veri limiti'", DefaultLanguageCode);
	#EndRegion

	#Region DimensionKind
	Item = Items.Add();
	Item.PredefinedDataName = "DimensionKind";
	TypesArray = New Array;
	TypesArray.Add(Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Dạng chỉ số';
							|ru = 'Вид аналитики';
							|en = 'Dimension kind'; fa = 'نوع بُعد';
							|it = 'Tipo di analitica';
							|pl = 'Rodzaj analityki';
							|tr = 'Boyut türü'", DefaultLanguageCode);
	#EndRegion

	#Region ExtDimensionType
	Item = Items.Add();
	Item.PredefinedDataName = "ExtDimensionType";
	TypesArray = New Array;
	TypesArray.Add(Type("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Dạng khoản mục';
							|ru = 'Вид субконто';
							|en = 'Extra dimension type'; fa = 'نوع بُعد اضافی';
							|it = 'Tipo di sottoconto';
							|pl = 'Rodzaj subkonto';
							|tr = 'Ekstra boyut türü'", DefaultLanguageCode);
	#EndRegion

	#Region SelectedValueSources
	Item = Items.Add();
	Item.PredefinedDataName = "SelectedValueSources";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Nguồn giá trị được chọn';
							|ru = 'Выбранные источники значений';
							|en = 'Selected value sources'; fa = 'منابع مقدار انتخاب‌شده';
							|it = 'Fonti di valori selezionate';
							|pl = 'Wybrane źródła wartości';
							|tr = 'Seçilen değer kaynakları'", DefaultLanguageCode);
	#EndRegion

	#Region DisplayedIndicators
	Item = Items.Add();
	Item.PredefinedDataName = "DisplayedIndicators";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.TypesOfDisplayedBudgetReportIndicators"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Đưa ra chỉ tiêu';
							|ru = 'Выводимые показатели';
							|en = 'Displayed indicators'; fa = 'شاخص‌های نمایش‌داده‌شده';
							|it = 'Indici visualizzati';
							|pl = 'Wyświetlane wskaźniki';
							|tr = 'Görüntülenen göstergeler'", DefaultLanguageCode);
	#EndRegion

	#Region DisplayWithParent
	Item = Items.Add();
	Item.PredefinedDataName = "DisplayWithParent";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Hiển thị với lớp trên';
							|ru = 'Выводить вместе с родительским';
							|en = 'Display with parent'; fa = 'نمایش با والد';
							|it = 'Mostrare insieme al genitore';
							|pl = 'Wyświetlaj razem z nadrzędnym';
							|tr = 'Üst öğelerle birlikte göster'", DefaultLanguageCode);
	#EndRegion

	#Region DisplayHeadersVertically
	Item = Items.Add();
	Item.PredefinedDataName = "DisplayHeadersVertically";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Hiển thị tiêu đề theo chiều dọc';
							|ru = 'Выводить заголовки по вертикали';
							|en = 'Display headers vertically'; fa = 'نمایش سرستون‌ها به صورت عمودی';
							|it = 'Display headers vertically';
							|pl = 'Display headers vertically';
							|tr = 'Başlıkları dikey olarak görüntüle'", DefaultLanguageCode);
	#EndRegion

	#Region DisplayGroupingTitle
	Item = Items.Add();
	Item.PredefinedDataName = "DisplayGroupingTitle";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Hiển thị tiêu đề nhóm';
							|ru = 'Выводить заголовок группировки';
							|en = 'Display grouping title'; fa = 'Display grouping title';
							|it = 'Visualizzare l''intestazione del raggruppamento';
							|pl = 'Wyświetlaj nagłówek grupowania';
							|tr = 'Gruplama başlıklarını göster'", DefaultLanguageCode);
	#EndRegion

	#Region DisplayItemTitle
	Item = Items.Add();
	Item.PredefinedDataName = "DisplayItemTitle";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Hiển thị tiêu đề mục';
							|ru = 'Выводить заголовок элемента';
							|en = 'Display item title'; fa = 'نمایش عنوان قلم';
							|it = 'Visualizzare l''intestazione dell''elemento';
							|pl = 'Wyświetlaj tytuł elementu';
							|tr = 'Öğe başlığını göster'", DefaultLanguageCode);
	#EndRegion

	#Region SelectItem
	Item = Items.Add();
	Item.PredefinedDataName = "SelectItem";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Chọn yếu tố';
							|ru = 'Выделить элемент';
							|en = 'Select item'; fa = 'انتخاب قلم';
							|it = 'Seleziona elemento';
							|pl = 'Zaznacz element';
							|tr = 'Öğeyi vurgula'", DefaultLanguageCode);
	#EndRegion

	#Region GroupHeader
	Item = Items.Add();
	Item.PredefinedDataName = "GroupHeader";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Nhóm tiêu đề';
							|ru = 'Заголовок группировки';
							|en = 'Grouping title'; fa = 'عنوان گروه‌بندی';
							|it = 'Titolo del raggruppamento';
							|pl = 'Nagłówek grupowania';
							|tr = 'Gruplama başlığı'", DefaultLanguageCode);
	#EndRegion

	#Region PeriodValue
	Item = Items.Add();
	Item.PredefinedDataName = "PeriodValue";
	TypesArray = New Array;
	TypesArray.Add(Type("Number"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Giá trị kỳ';
							|ru = 'Значение периода';
							|en = 'Period value'; fa = 'مقدار دوره';
							|it = 'Valore del periodo';
							|pl = 'Wartość okresu';
							|tr = 'Dönem değeri'", DefaultLanguageCode);
	#EndRegion

	#Region DimensionName
	Item = Items.Add();
	Item.PredefinedDataName = "DimensionName";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Tên đo lường';
							|ru = 'Имя измерения';
							|en = 'Dimension name'; fa = 'نام بُعد';
							|it = 'Nome della dimensione';
							|pl = 'Nazwa pomiaru';
							|tr = 'Boyut adı'", DefaultLanguageCode);
	#EndRegion

	#Region ExcludeEnteredDocumentDataDuringCalculation
	Item = Items.Add();
	Item.PredefinedDataName = "ExcludeEnteredDocumentDataDuringCalculation";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Loại trừ dữ liệu tài liệu đầu vào trong khi tính toán';
							|ru = 'Исключить данные вводимого документа при расчете';
							|en = 'Exclude entered document data during calculation'; fa = 'مستثنی کردن داده‌های سند واردشده هنگام محاسبه';
							|it = 'Escludere dati del documento inserito durante il calcolo';
							|pl = 'Wyklucz dane wprowadzonego dokumentu podczas obliczania';
							|tr = 'Hesaplamada giriş belgesi verilerini hariç tut'", DefaultLanguageCode);
	#EndRegion

	#Region UseFilterByCompany
	Item = Items.Add();
	Item.PredefinedDataName = "UseFilterByCompany";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Sử dụng lọc theo doanh nghiệp';
							|ru = 'Использовать фильтр по организации';
							|en = 'Use filter by company'; fa = 'استفاده از فیلتر بر اساس شرکت';
							|it = 'Utilizzare il filtro per aziende';
							|pl = 'Używaj filtr wg firm';
							|tr = 'İş yerine göre filtre kullan'", DefaultLanguageCode);
	#EndRegion

	#Region UseFilterByDepartment
	Item = Items.Add();
	Item.PredefinedDataName = "UseFilterByDepartment";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Sử dụng lọc theo bộ phận';
							|ru = 'Использовать фильтр по подразделению';
							|en = 'Use filter by business unit'; fa = 'استفاده از فیلتر بر اساس واحد تجاری';
							|it = 'Utilizzare il filtro per settore';
							|pl = 'Używaj filtru wg działu';
							|tr = 'Departmana göre filtre kullan'", DefaultLanguageCode);
	#EndRegion

	#Region UseStatusFilter
	Item = Items.Add();
	Item.PredefinedDataName = "UseStatusFilter";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Sử dụng bộ lọc theo trạng thái';
							|ru = 'Использовать фильтр по статусу';
							|en = 'Use filter by status'; fa = 'استفاده از فیلتر بر اساس وضعیت';
							|it = 'Использовать фильтр по статусу';
							|pl = 'Use filter by status';
							|tr = 'Duruma göre filtre kullan'", DefaultLanguageCode);
	#EndRegion

	#Region UseFilterScenario
	Item = Items.Add();
	Item.PredefinedDataName = "UseFilterScenario";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Sử dụng lọc theo kịch bản';
							|ru = 'Использовать фильтр по сценарию';
							|en = 'Use filter by scenario'; fa = 'Use filter by scenario';
							|it = 'Utilizzare il filtro per scenario';
							|pl = 'Używaj filtr wg scenariuszu';
							|tr = 'Senaryoya göre filtre kullan'", DefaultLanguageCode);
	#EndRegion

	#Region SourceAllElements
	Item = Items.Add();
	Item.PredefinedDataName = "SourceAllElements";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Nguồn toàn bộ giá trị';
							|ru = 'Источник все значения';
							|en = 'Source all values'; fa = 'Source all values';
							|it = 'Fonte tutti i valori';
							|pl = 'Źródło wszystkie wartości';
							|tr = 'Tüm değerlerin kaynağı'", DefaultLanguageCode);
	#EndRegion

	#Region ReportRowCode
	Item = Items.Add();
	Item.PredefinedDataName = "ReportRowCode";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Mã dòng báo cáo';
							|ru = 'Код строки отчета';
							|en = 'Report line code'; fa = 'کد سطر گزارش';
							|it = 'Codice riga del report';
							|pl = 'Kod wiersza raportu';
							|tr = 'Rapor satır kodu'", DefaultLanguageCode);
	#EndRegion

	#Region CellColumn
	Item = Items.Add();
	Item.PredefinedDataName = "CellColumn";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.FinancialReportItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Cột ô';
							|ru = 'Колонка ячейки';
							|en = 'Cell column'; fa = 'ستون سلول';
							|it = 'Colonna della cella';
							|pl = 'Kolumna komórki';
							|tr = 'Hücre sütunu'", DefaultLanguageCode);
	#EndRegion

	#Region GroupingPeriodEnd
	Item = Items.Add();
	Item.PredefinedDataName = "GroupingPeriodEnd";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Cuối kỳ gom nhóm';
							|ru = 'Конец периода группировки';
							|en = 'Grouping period end'; fa = 'پایان دوره گروه‌بندی';
							|it = 'Fine del periodo di raggruppamento';
							|pl = 'Koniec okresu grupowania';
							|tr = 'Gruplama döneminin sonu'", DefaultLanguageCode);
	#EndRegion

	#Region GroupingPeriodStart
	Item = Items.Add();
	Item.PredefinedDataName = "GroupingPeriodStart";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Đầu kỳ nhóm';
							|ru = 'Начало периода группировки';
							|en = 'Grouping period start'; fa = 'شروع دوره گروه‌بندی';
							|it = 'Inizio del periodo del raggruppamento';
							|pl = 'Początek okresu grupowania';
							|tr = 'Gruplama döneminin başlangıcı'", DefaultLanguageCode);
	#EndRegion

	#Region OpeningBalance
	Item = Items.Add();
	Item.PredefinedDataName = "OpeningBalance";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Dư đầu';
							|ru = 'Начальное сальдо';
							|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
							|it = 'Saldo iniziale';
							|pl = 'Saldo początkowe';
							|tr = 'Açılış bakiyesi'", DefaultLanguageCode);
	#EndRegion
	#Region NonMonetaryItem
	Item = Items.Add();
	Item.PredefinedDataName = "NonMonetaryItem";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.NonMonetaryItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Chỉ tiêu phi tiền tệ';
							|ru = 'Немонетарный показатель';
							|en = 'Non-monetary item'; fa = 'قلم غیرپولی';
							|it = 'Indice non monetario';
							|pl = 'Wskaźnik niemonetarny';
							|tr = 'Gayrinakdi gösterge'", DefaultLanguageCode);
	#EndRegion
	#Region NonFinancialItem
	Item = Items.Add();
	Item.PredefinedDataName = "NonFinancialItem";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.NonFinancialItemsOfBudgets"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Chỉ tiêu phi tài chính';
							|ru = 'Нефинансовый показатель';
							|en = 'Non-financial item'; fa = 'قلم غیرمالی';
							|it = 'Indicatore non finanziario';
							|pl = 'Wskaźnik niefinansowany';
							|tr = 'Finansal olmayan gösterge'", DefaultLanguageCode);
	#EndRegion

	#Region LowerBoundOfData
	Item = Items.Add();
	Item.PredefinedDataName = "LowerBoundOfData";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Ranh giới dưới của dữ liệu';
							|ru = 'Нижняя граница данных';
							|en = 'Lower bound of data'; fa = 'حد پایین داده';
							|it = 'Limite inferiore dei dati';
							|pl = 'Dolna granica danych';
							|tr = 'Alt veri limiti'", DefaultLanguageCode);
	#EndRegion

	#Region Organization
	Item = Items.Add();
	Item.PredefinedDataName = "Organization";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.Companies"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Doanh nghiệp';
							|ru = 'Организация';
							|en = 'Company'; fa = 'Company';
							|it = 'Azienda';
							|pl = 'Company';
							|tr = 'İş yeri'", DefaultLanguageCode);
	#EndRegion

	#Region DisplayColumnNumbering
	Item = Items.Add();
	Item.PredefinedDataName = "DisplayColumnNumbering";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Hiển thị đánh số cột';
							|ru = 'Отображать нумерацию колонок';
							|en = 'Display column numbering'; fa = 'نمایش شماره‌گذاری ستون‌ها';
							|it = 'Visualizzare la numerazione di colonne';
							|pl = 'Wyświetlać numerację kolumn';
							|tr = 'Sütun numarasını görüntüle'", DefaultLanguageCode);
	#EndRegion

	#Region DisplayRowsNumbering
	Item = Items.Add();
	Item.PredefinedDataName = "DisplayRowsNumbering";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Hiển thị đánh số dòng';
							|ru = 'Отображать нумерацию строк';
							|en = 'Display line numbering'; fa = 'نمایش شماره‌گذاری سطرها';
							|it = 'Visualizzare la numerazione di righe';
							|pl = 'Wyświetlać numerację wierszy';
							|tr = 'Satır numarasını görüntüle'", DefaultLanguageCode);
	#EndRegion

	#Region Periodicity
	Item = Items.Add();
	Item.PredefinedDataName = "Periodicity";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.Periodicity"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Tính định kỳ';
							|ru = 'Периодичность';
							|en = 'Frequency'; fa = 'تناوب';
							|it = 'Periodicità';
							|pl = 'Frequency';
							|tr = 'Sıklık'", DefaultLanguageCode);
	#EndRegion

	#Region OffsetFrequency
	Item = Items.Add();
	Item.PredefinedDataName = "OffsetFrequency";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.Periodicity"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Định kỳ hỗn hợp';
							|ru = 'Периодичность смещения';
							|en = 'Offset frequency'; fa = 'تناوب جابه‌جایی';
							|it = 'Periodicità di spostamento';
							|pl = 'Okresowość przesunięcia';
							|tr = 'Kayma sıklığı'", DefaultLanguageCode);
	#EndRegion

	#Region PeriodOfShift
	Item = Items.Add();
	Item.PredefinedDataName = "PeriodOfShift";
	TypesArray = New Array;
	TypesArray.Add(Type("Number"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Kỳ hỗn hợp';
							|ru = 'Период смещения';
							|en = 'Offset period'; fa = 'دوره جابه‌جایی';
							|it = 'Periodo di spostamento';
							|pl = 'Okres przesunięcia';
							|tr = 'Kayma dönemi'", DefaultLanguageCode);
	#EndRegion

	#Region Department
	Item = Items.Add();
	Item.PredefinedDataName = "Department";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Bộ phận';
							|ru = 'Подразделение';
							|en = 'Business unit'; fa = 'Business unit';
							|it = 'Reparto';
							|pl = 'Dział';
							|tr = 'Departman'", DefaultLanguageCode);
	#EndRegion

	#Region BudgetBalanceItem
	Item = Items.Add();
	Item.PredefinedDataName = "BudgetBalanceItem";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.BudgetBalanceItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Chỉ tiêu ngân sách';
							|ru = 'Показатель бюджетов';
							|en = 'Budget balance item'; fa = 'قلم مانده بودجه';
							|it = 'Indice dei bilanci';
							|pl = 'Wskaźnik budżetowy';
							|tr = 'Bütçe kalemi'", DefaultLanguageCode);
	#EndRegion
	#Region PeriodPresentation
	Item = Items.Add();
	Item.PredefinedDataName = "PeriodPresentation";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.PeriodPresentation"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Trình bày kỳ';
							|ru = 'Представление периода';
							|en = 'Period presentation'; fa = 'نمایش دوره';
							|it = 'Visualizzazione del periodo';
							|pl = 'Widok okresu';
							|tr = 'Dönem sunumu'", DefaultLanguageCode);
	#EndRegion
	#Region PrivilegedMode
	Item = Items.Add();
	Item.PredefinedDataName = "PrivilegedMode";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Chế độ đặc quyền';
							|ru = 'Привилегированный режим';
							|en = 'Privileged mode'; fa = 'Privileged mode';
							|it = 'Modalità del kernel';
							|pl = 'Tryb uprzywilejowany';
							|tr = 'İmtiyaz modu'", DefaultLanguageCode);
	#EndRegion

	#Region Note
	Item = Items.Add();
	Item.PredefinedDataName = "Note";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Ghi chú';
							|ru = 'Примечание';
							|en = 'Note'; fa = 'یادداشت';
							|it = 'Nota';
							|pl = 'Note';
							|tr = 'Not'", DefaultLanguageCode);
	#EndRegion

	#Region EnableEdit
	Item = Items.Add();
	Item.PredefinedDataName = "EnableEdit";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Được phép thêm';
							|ru = 'Разрешено добавление';
							|en = 'Adding is allowed'; fa = 'Adding is allowed';
							|it = 'Aggiunta concessa';
							|pl = 'Zezwolono dodawanie';
							|tr = 'Eklemeye izin verildi'", DefaultLanguageCode);
	#EndRegion

	#Region Sort
	Item = Items.Add();
	Item.PredefinedDataName = "Sort";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Sắp xếp';
							|ru = 'Сортировка';
							|en = 'Sort'; fa = 'مرتب‌سازی';
							|it = 'Smistamento';
							|pl = 'Sort';
							|tr = 'Sıralama'", DefaultLanguageCode);
	#EndRegion

	#Region FillingMethod
	Item = Items.Add();
	Item.PredefinedDataName = "FillingMethod";
	TypesArray = New Array;
	TypesArray.Add(Type("Number"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Phương thức điền';
							|ru = 'Способ заполнения';
							|en = 'Filling method'; fa = 'روش پرکردن';
							|it = 'Metodo di compilazione';
							|pl = 'Sposób wypełnienia';
							|tr = 'Doldurma yöntemi'", DefaultLanguageCode);
	#EndRegion

	#Region BudgetFlowItem
	Item = Items.Add();
	Item.PredefinedDataName = "BudgetFlowItem";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.BudgetFlowItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Khoản mục ngân sách';
							|ru = 'Статья бюджетов';
							|en = 'Budget flow item'; fa = 'قلم جریان بودجه';
							|it = 'Voce di bilanci';
							|pl = 'Pozycja budżetowa';
							|tr = 'Bütçe kalemi'", DefaultLanguageCode);
	#EndRegion

	#Region CellRow
	Item = Items.Add();
	Item.PredefinedDataName = "CellRow";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.FinancialReportItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Dòng ô';
							|ru = 'Строка ячейки';
							|en = 'Cell line'; fa = 'سطر سلول';
							|it = 'Riga della cella';
							|pl = 'Wiersz komórki';
							|tr = 'Hücre satırı'", DefaultLanguageCode);
	#EndRegion

	#Region Scenario
	Item = Items.Add();
	Item.PredefinedDataName = "Scenario";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.BudgetingScenarios"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Kịch bản';
							|ru = 'Сценарий';
							|en = 'Scenario'; fa = 'سناریو';
							|it = 'Scenario';
							|pl = 'Scenario';
							|tr = 'Senaryo'", DefaultLanguageCode);
	#EndRegion
	#Region GLAccount_
	Item = Items.Add();
	Item.PredefinedDataName = "GLAccount_";
	TypesArray = New Array;
	TypesArray.Add(Type("ChartOfAccountsRef.International"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Tài khoản hệ thống tài khoản';
							|ru = 'Счет плана счетов';
							|en = 'Account of chart of accounts'; fa = 'حساب سرفصل حساب‌ها';
							|it = 'Conto del piano di conti';
							|pl = 'Kalkulacja planu rachunków';
							|tr = 'Hesap planı hesabı'", DefaultLanguageCode);
	#EndRegion
	#Region Text
	Item = Items.Add();
	Item.PredefinedDataName = "Text";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Nội dung';
							|ru = 'Текст';
							|en = 'Text'; fa = 'متن';
							|it = 'Testo';
							|pl = 'Text';
							|tr = 'Metin'", DefaultLanguageCode);
	#EndRegion

	#Region IndicatorValueType
	Item = Items.Add();
	Item.PredefinedDataName = "IndicatorValueType";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.ValueTypesOfBudgetReportIndicators"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Kiểu giá trị chỉ số';
							|ru = 'Тип значения показателя';
							|en = 'Indicator value type'; fa = 'نوع مقدار شاخص';
							|it = 'Tipo di valore dell''indice';
							|pl = 'Typ wartości wskaźnika';
							|tr = 'Gösterge değer türü'", DefaultLanguageCode);
	#EndRegion

	#Region DimensionType
	Item = Items.Add();
	Item.PredefinedDataName = "DimensionType";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.TypesOfBudgetReportDimensions"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Loại đo lường';
							|ru = 'Тип измерения';
							|en = 'Dimension type'; fa = 'نوع بُعد';
							|it = 'Tipo di dimensione';
							|pl = 'Typ pomiaru';
							|tr = 'Ölçüm türü'", DefaultLanguageCode);
	#EndRegion

	#Region TotalType
	Item = Items.Add();
	Item.PredefinedDataName = "TotalType";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.TypesOfTotals"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Dạng tổng';
							|ru = 'Тип итога';
							|en = 'Total type'; fa = 'نوع جمع';
							|it = 'Tipo totale';
							|pl = 'Typ wyników';
							|tr = 'Toplam türü'", DefaultLanguageCode);
	#EndRegion

	#Region EditedValueType
	Item = Items.Add();
	Item.PredefinedDataName = "EditedValueType";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Kiểu giá trị có thể chỉnh sửa';
							|ru = 'Тип редактируемого значения';
							|en = 'Edited value type'; fa = 'Edited value type';
							|it = 'Tipo di valore modificato';
							|pl = 'Typ edytowanej wartości';
							|tr = 'Değerlerin düzenlenme türü'", DefaultLanguageCode);
	#EndRegion

	#Region OnlyForPrinting
	Item = Items.Add();
	Item.PredefinedDataName = "OnlyForPrinting";
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.BudgetFlowItems"));
	TypesArray.Add(Type("CatalogRef.Currencies"));
	TypesArray.Add(Type("CatalogRef.Companies"));
	TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	TypesArray.Add(Type("Boolean"));
	TypesArray.Add(Type("CatalogRef.FinancialReportItems"));
	TypesArray.Add(Type("EnumRef.Periodicity"));
	TypesArray.Add(Type("CatalogRef.BudgetBalanceItems"));
	TypesArray.Add(Type("EnumRef.BudgetingFormulaKinds"));
	TypesArray.Add(Type("EnumRef.ValueTypesOfBudgetReportIndicators"));
	TypesArray.Add(Type("EnumRef.TypesOfBudgetReportDimensions"));
	TypesArray.Add(Type("String"));
	TypesArray.Add(Type("EnumRef.TypesOfDisplayedBudgetReportIndicators"));
	TypesArray.Add(Type("Number"));
	TypesArray.Add(Type("ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions"));
	TypesArray.Add(Type("CatalogRef.NonFinancialItemsOfBudgets"));
	TypesArray.Add(Type("CatalogRef.BudgetingScenarios"));
	TypesArray.Add(Type("EnumRef.TypesOfTotals"));
	TypesArray.Add(Type("ChartOfAccountsRef.International"));//
	TypesArray.Add(Type("EnumRef.PeriodPresentation"));
	TypesArray.Add(Type("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes"));
	TypesArray.Add(Type("CatalogRef.NonMonetaryItems"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Chỉ in';
							|ru = 'Только для печати';
							|en = 'Only for printing'; fa = 'فقط برای چاپ';
							|it = 'Solo per la stampa';
							|pl = 'Tylko do druku';
							|tr = 'Sadece yazdırma için'", DefaultLanguageCode);
	#EndRegion

	#Region Accuracy
	Item = Items.Add();
	Item.PredefinedDataName = "Accuracy";
	TypesArray = New Array;
	TypesArray.Add(Type("Number"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Mức độ chính xác';
							|ru = 'Точность';
							|en = 'Precision'; fa = 'دقت';
							|it = 'Precisione';
							|pl = 'Dokładność';
							|tr = 'Duyarlılık'", DefaultLanguageCode);
	#EndRegion

	#Region Formula
	Item = Items.Add();
	Item.PredefinedDataName = "Formula";
	TypesArray = New Array;
	TypesArray.Add(Type("String"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Công thức';
							|ru = 'Формула';
							|en = 'Formula'; fa = 'فرمول';
							|it = 'Formula';
							|pl = 'Wzór';
							|tr = 'Formül'", DefaultLanguageCode);
	#EndRegion

	#Region GroupFormula
	Item = Items.Add();
	Item.PredefinedDataName = "GroupFormula";
	TypesArray = New Array;
	TypesArray.Add(Type("EnumRef.BudgetingFormulaKinds"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Công thức';
							|ru = 'Формула';
							|en = 'Formula'; fa = 'فرمول';
							|it = 'Formula';
							|pl = 'Wzór';
							|tr = 'Formül'", DefaultLanguageCode);
	#EndRegion

	#Region ThisIsDimensionOther
	Item = Items.Add();
	Item.PredefinedDataName = "ThisIsDimensionOther";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Đây là chỉ số khác';
							|ru = 'Это аналитика прочее';
							|en = 'This is dimension other'; fa = 'این بُعد سایر است';
							|it = 'Analitica altro';
							|pl = 'To jest analityka inne';
							|tr = 'Bu başka bir boyut'", DefaultLanguageCode);
	#EndRegion

	#Region ThisIsReference
	Item = Items.Add();
	Item.PredefinedDataName = "ThisIsReference";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Đây là liên quan';
							|ru = 'Это связанный';
							|en = 'This is associated'; fa = 'این مرتبط است';
							|it = 'Correlato';
							|pl = 'Jest to związane';
							|tr = 'Bu bağlantılıdır'", DefaultLanguageCode);
	#EndRegion

	#Region OutputIndicatorsOfSimilarPeriodsOfPreviousYears
	Item = Items.Add();
	Item.PredefinedDataName = "OutputIndicatorsOfSimilarPeriodsOfPreviousYears";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Hiển thị chỉ tiêu cùng kỳ các năm trước';
							|ru = 'Выводить показатели аналогичных периодов прошлых лет';
							|en = 'Show indicators for the same periods of previous years'; fa = 'نمایش شاخص‌های دوره‌های مشابه سال‌های قبل';
							|it = 'Rilevare indicatori di periodi analoghi degli anni passati';
							|pl = 'Wyświetlaj wskaźniki analogicznych okresów zeszłych lat';
							|tr = 'Önceki yılların benzer dönemlerinin göstergelerini göster'", DefaultLanguageCode);
	#EndRegion
	
	#Region DisplayIndicatorsOfPreviousPeriods
	Item = Items.Add();
	Item.PredefinedDataName = "DisplayIndicatorsOfPreviousPeriods";
	TypesArray = New Array;
	TypesArray.Add(Type("Boolean"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Hiển thị chỉ tiêu của các kỳ trước';
							|ru = 'Выводить показатели предыдущих периодов';
							|en = 'Show indicators for previous periods'; fa = 'نمایش شاخص‌های دوره‌های قبل';
							|it = 'Rilevare indicatori dei periodi precedenti';
							|pl = 'Wyświetlaj wskaźniki poprzednich okresów';
							|tr = 'Önceki dönemlerin göstergelerini göster'", DefaultLanguageCode);
	#EndRegion
	
	#Region NumberOfPreviousYears
	Item = Items.Add();
	Item.PredefinedDataName = "NumberOfPreviousYears";
	TypesArray = New Array;
	TypesArray.Add(Type("Number"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Số năm trước';
							|ru = 'Количество предыдущих лет';
							|en = 'Number of previous years'; fa = 'تعداد سال‌های قبل';
							|it = 'Numero anni precedenti';
							|pl = 'Ilość poprzednich lat';
							|tr = 'Önceki yılların sayısı'", DefaultLanguageCode);
	#EndRegion
	
	#Region NumberOfPreviousPeriods
	Item = Items.Add();
	Item.PredefinedDataName = "NumberOfPreviousPeriods";
	TypesArray = New Array;
	TypesArray.Add(Type("Number"));
	TypeDetails = New TypeDescription(TypesArray);
	Item.ValueType = TypeDetails;
	Item.Description = NStr("vi = 'Số lượng các kỳ trước';
							|ru = 'Количество предыдущих периодов';
							|en = 'Number of previous periods'; fa = 'تعداد دوره‌های قبل';
							|it = 'Numero periodi precedenti';
							|pl = 'Ilość poprzednich okresów';
							|tr = 'Önceki dönemlerin sayısı'", DefaultLanguageCode);
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - ChartOfCharacteristicTypesObject.ItemAttributesOfFinancialReports - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

#EndRegion

#EndIf
