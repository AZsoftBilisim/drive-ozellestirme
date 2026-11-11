#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   VariantKey - String - Option Key
//
// Returns:
//   ValueTableRow - From:
//    *Manager - String -
//    *Presentation - String -
//    *MultipleChoice - Boolean - 
//    *Importance - String -
//    *VariantKey - String -
Function AddReportCommand(ReportsCommands, VariantKey = "") Export

	If AccessRight("View", Metadata.Reports.LaborInputOfProductionOrder) 
			And GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.LaborInputOfProductionOrder.FullName();
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		If ValueIsFilled(VariantKey) Then
			ReportCommand.VariantKey = VariantKey;
		EndIf;
		
		If VariantKey = "LaborInputByOrder" Then
			
			ReportCommand.Presentation = NStr("vi = 'Cường độ lao động của đơn hàng';
												|ru = 'Трудоемкость заказа';
												|en = 'Order labor input'; fa = 'Order labor input';
												|it = 'Трудоемкость заказа';
												|pl = 'Order labor input';
												|tr = 'Siparişin iş gücü girdisi'");
			
		ElsIf VariantKey = "LaborInputByBatch" Then
			
			ReportCommand.Presentation = NStr("vi = 'Cường độ lao động theo lô hàng';
												|ru = 'Трудоемкость по партии';
												|en = 'Labor input by lot'; fa = 'کار ورودی بر اساس لات';
												|it = 'Трудоемкость по партии';
												|pl = 'Labor input by lot';
												|tr = 'Lota göre iş gücü girdisi'");
			
		ElsIf VariantKey = "LaborInputByStage" Then
			
			ReportCommand.Presentation = NStr("vi = 'Cường độ lao động theo công đoạn';
												|ru = 'Трудоемкость по этапу';
												|en = 'Labor input by stage'; fa = 'کار ورودی بر اساس مرحله';
												|it = 'Трудоемкость по этапу';
												|pl = 'Labor input by stage';
												|tr = 'Aşamaya göre iş gücü girdisi'");
		
		EndIf;
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.LaborInputOfProductionOrder);
	DescriptionOfReport.DefineFormSettings = True;

	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "LaborInputByOrder");
	OptionDetails.Description = NStr("vi = 'Cường độ lao động của đơn hàng sản xuất';
									|ru = 'Трудоемкость заказа на производство';
									|en = 'Labor input of production order'; fa = 'کار ورودی سفارش تولید';
									|it = 'Трудоемкость заказа на производство';
									|pl = 'Labor input of production order';
									|tr = 'Üretim emrinin iş gücü girdisi'");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá trạng thái đơn hàng sản xuất theo công lao động dự tính và thực tế.';
									|ru = 'Оценка состояния заказа на производство по плановым и фактическим трудозатратам.';
									|en = 'Evaluate the state of production orders by planned and actual labor costs.'; fa = 'Evaluate the state of production orders by planned and actual labor costs.';
									|it = 'Оценка состояния заказа на производство по плановым и фактическим трудозатратам.';
									|pl = 'Evaluate the state of production orders by planned and actual labor costs.';
									|tr = 'Planlanan ve fiilî iş gücü maliyetlerine göre üretim emrinin durumunun değerlemesi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "LaborInputByBatch");
	OptionDetails.Description = NStr("vi = 'Cường độ lao động của đơn hàng sản xuất theo lô hàng';
									|ru = 'Трудоемкость заказов на производство по партии';
									|en = 'Labor input of production orders by lot'; fa = 'Labor input of production orders by lot';
									|it = 'Трудоемкость заказов на производство по партии';
									|pl = 'Labor input of production orders by lot';
									|tr = 'Lota göre üretim emirlerinin iş gücü girdisi'");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá trạng thái theo công lao động dự tính và thực tế theo lô hàng sản xuất.';
									|ru = 'Оценка состояния по плановым и фактическим трудозатратам по партиям производства.';
									|en = 'Evaluate the state by planned and actual labor costs by production lots.'; fa = 'Evaluate the state by planned and actual labor costs by production lots.';
									|it = 'Оценка состояния по плановым и фактическим трудозатратам по партиям производства.';
									|pl = 'Evaluate the state by planned and actual labor costs by production lots.';
									|tr = 'Üretim lotları kapsamında göre planlanan ve fiilî iş gücü maliyetlerine göre durumun değerlemesi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "LaborInputByStage");
	OptionDetails.Description = NStr("vi = 'Cường độ lao động của đơn hàng sản xuất theo công đoạn';
									|ru = 'Трудоемкость заказов на производство по этапам';
									|en = 'Labor input of production orders by stages'; fa = 'Labor input of production orders by stages';
									|it = 'Трудоемкость заказов на производство по этапам';
									|pl = 'Labor input of production orders by stages';
									|tr = 'Aşamalara göre üretim emirlerinin iş gücü girdisi'");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá trạng thái theo công lao động dự tính và thực tế theo công đoạn sản xuất.';
									|ru = 'Оценка состояния по плановым и фактическим трудозатратам по этапам производства.';
									|en = 'Evaluate the state by planned and actual labor costs by production stages.'; fa = 'Evaluate the state by planned and actual labor costs by production stages.';
									|it = 'Оценка состояния по плановым и фактическим трудозатратам по этапам производства.';
									|pl = 'Evaluate the state by planned and actual labor costs by production stages.';
									|tr = 'Üretim aşamaları kapsamında göre planlanan ve fiilî iş gücü maliyetlerine göre durumun değerlemesi.'");
	
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf