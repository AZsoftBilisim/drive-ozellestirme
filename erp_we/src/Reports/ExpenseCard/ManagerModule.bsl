// @strict-types


#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ExpenseCard);
	DescriptionOfReport.LongDesc = 
		NStr("vi = 'Phân tích việc hình thành và xử lý/phân bổ chi phí theo phương án phân bổ đã chỉ định theo trình tự thời gian.
			|Liên quan đến các chi phí có phương án phân bổ với số dư chuyển đổi giữa các tháng.';
			|ru = 'Анализ формирования и выбытия/распределения расхода по указанному варианту распределения в хронологическом порядке.
			|Актуально для расходов с вариантами распределения, предполагающими переходящий остаток между месяцами.';
			|en = 'Analysis of generating and disposing/allocating expenses according to the specified allocation option in chronological order.
			|You can use it for expenses with allocation options involving carryforward between months.'; fa = 'Analysis of generating and disposing/allocating expenses according to the specified allocation option in chronological order.
			|You can use it for expenses with allocation options involving carryforward between months.';
			|it = 'Анализ формирования и выбытия/распределения расхода по указанному варианту распределения в хронологическом порядке.
			|Актуально для расходов с вариантами распределения, предполагающими переходящий остаток между месяцами.';
			|pl = 'Analysis of generating and disposing/allocating expenses according to the specified allocation option in chronological order.
			|You can use it for expenses with allocation options involving carryforward between months.';
			|tr = 'Belirlenen dağıtım seçeneğine göre kronolojik sırayla giderin oluşumu ve elden çıkarılması/dağıtımı  analizi.
			|Aylar arası yekun aktarma gereken dağıtım seçenekli giderler için geçerlidir. '");
	DescriptionOfReport.DefineFormSettings = True;

	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = 
		NStr("vi = 'Phân tích việc hình thành và xử lý/phân bổ chi phí theo phương án phân bổ đã chỉ định theo trình tự thời gian.
			|Liên quan đến các chi phí có phương án phân bổ với số dư chuyển đổi giữa các tháng.';
			|ru = 'Анализ формирования и выбытия/распределения расхода по указанному варианту распределения в хронологическом порядке.
			|Актуально для расходов с вариантами распределения, предполагающими переходящий остаток между месяцами.';
			|en = 'Analysis of generating and disposing/allocating expenses according to the specified allocation option in chronological order.
			|You can use it for expenses with allocation options involving carryforward between months.'; fa = 'Analysis of generating and disposing/allocating expenses according to the specified allocation option in chronological order.
			|You can use it for expenses with allocation options involving carryforward between months.';
			|it = 'Анализ формирования и выбытия/распределения расхода по указанному варианту распределения в хронологическом порядке.
			|Актуально для расходов с вариантами распределения, предполагающими переходящий остаток между месяцами.';
			|pl = 'Analysis of generating and disposing/allocating expenses according to the specified allocation option in chronological order.
			|You can use it for expenses with allocation options involving carryforward between months.';
			|tr = 'Belirlenen dağıtım seçeneğine göre kronolojik sırayla giderin oluşumu ve elden çıkarılması/dağıtımı  analizi.
			|Aylar arası yekun aktarma gereken dağıtım seçenekli giderler için geçerlidir. '");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ToDeferredExpenses");
	OptionDetails.LongDesc = NStr("vi = 'Đối với phương án phân bổ ""Cho chi phí trả trước"".';
									|ru = 'Для варианта распределения ""На расходы будущих периодов"".';
									|en = 'For the ""To deferred expenses"" allocation option.'; fa = 'For the ""To deferred expenses"" allocation option.';
									|it = 'Для варианта распределения ""На расходы будущих периодов"".';
									|pl = 'For the ""To deferred expenses"" allocation option.';
									|tr = '""Ertelenmiş giderlere"" dağıtım seçeneği için.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ToInventoryCost");
	OptionDetails.LongDesc = NStr("vi = 'Đối với phương án phân bổ ""Cho giá vốn hàng hóa"".';
									|ru = 'Для варианта распределения ""На себестоимость товаров"".';
									|en = 'For the ""To inventory cost"" allocation option.'; fa = 'For the ""To inventory cost"" allocation option.';
									|it = 'Для варианта распределения ""На себестоимость товаров"".';
									|pl = 'For the ""To inventory cost"" allocation option.';
									|tr = '""Stok maliyetine"" dağıtım seçeneği için.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ToProductionCosts");
	OptionDetails.LongDesc = NStr("vi = 'Đối với phương án phân bổ ""Cho giá vốn sản xuất (được phân bổ)"".';
									|ru = 'Для варианта распределения ""На себестоимость производства (распределяемые)"".';
									|en = 'For the ""To production cost (overheads)"" allocation option.'; fa = 'For the ""To production cost (overheads)"" allocation option.';
									|it = 'Для варианта распределения ""На себестоимость производства (распределяемые)"".';
									|pl = 'For the ""To production cost (overheads)"" allocation option.';
									|tr = '""Üretim maliyetine (dağıtılan)"" dağıtım seçeneği için.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ToCostOfGoodsSold");
	OptionDetails.LongDesc = NStr("vi = 'Đối với phương án phân bổ ""Cho giá vốn hàng hóa"".';
									|ru = 'Для варианта распределения ""На себестоимость продаж"".';
									|en = 'For the ""To cost of goods sold"" allocation option.'; fa = 'For the ""To cost of goods sold"" allocation option.';
									|it = 'Для варианта распределения ""На себестоимость продаж"".';
									|pl = 'For the ""To cost of goods sold"" allocation option.';
									|tr = '""Satılan malların maliyetine"" dağıtım seçeneği için.'");
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

// Code of procedures and functions

#EndRegion

#Region Internal

// Code of procedures and functions

#EndRegion

#Region Private

// Code of procedures and functions

#EndRegion

#EndIf
