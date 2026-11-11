#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CriteriaCorrelationOnChange(Item)
	
	Regulator = Items.CriteriaCorrelation;
	Weights_ = WeightsByRegulatorPosition(
		Regulator.MinValue, Regulator.MaxValue, CriteriaCorrelation);
	
	// It is assumed that the time criterion is on the left, and the cost criterion is on the right of the scale.
	Object.ValueMinimizeTime = Weights_.Weight1;
	Object.ValueMinimizeCost = Weights_.Weight2;
	
	FillInExplanationOfRatioOfCriteria(ThisObject);
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()

	SetPositionAndRatioOfCriteria();
	FillInExplanationOfRatioOfCriteria(ThisObject);

EndProcedure

&AtServer
Procedure SetPositionAndRatioOfCriteria()
	
	Regulator = Items.CriteriaCorrelation;
	CriteriaCorrelation = RegulatorPositionByWeight(
		Regulator.MinValue, Regulator.MaxValue, Object.ValueMinimizeTime);
	
EndProcedure

&AtClientAtServerNoContext
Function WeightsByRegulatorPosition(MinValue_, Max_Value, CurrentValue)
	
	Result = New Structure("Weight1, Weight2", 0.5, 0.5);
	
	NumberOfDivisions = Max_Value - MinValue_;
	If NumberOfDivisions > 0 Then
		DivisionPrice = Round(1/NumberOfDivisions, 3);
		Result.Weight1 = Round(1-((CurrentValue-MinValue_)*DivisionPrice), 3);
		Result.Weight2 = 1 - Result.Weight1;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function RegulatorPositionByWeight(MinValue_, Max_Value, Weight)
	
	NumberOfDivisions = Max_Value - MinValue_;
	If NumberOfDivisions > 0 Then
		DivisionPrice = Round(1/NumberOfDivisions, 3);
		Result = (1-Weight)/DivisionPrice+MinValue_;
	Else
		Result = MinValue_;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure FillInExplanationOfRatioOfCriteria(Form)
	
	If Form.Object.ValueMinimizeTime >= Form.Object.ValueMinimizeCost Then
		EstimateTime = Round(Form.Object.ValueMinimizeTime, 2) * 100;
		EstimateCost = 100 - EstimateTime;
	Else
		EstimateCost = Round(Form.Object.ValueMinimizeCost, 2) * 100;
		EstimateTime = 100 - EstimateCost;
	EndIf;
	
	If EstimateTime = EstimateCost Then
		
		Form.Items.DecodingTheRatioOfCriteria.Title = NStr("vi = 'Đánh giá hiện tại: tiêu chí tối ưu là tương đương.';
															|ru = 'Текущая оценка: критерии оптимизации эквивалентны.';
															|en = 'Current evaluation: optimization criteria are equivalent.'; fa = 'Current evaluation: optimization criteria are equivalent.';
															|it = 'Valutazione attuale: i criteri di ottimizzazione sono equivalenti.';
															|pl = 'Bieżąca ocena: kryteria optymalizacji są równoważne.';
															|tr = 'Mevcut değerlendirme: Optimizasyon kriterleri eşdeğerdir.'");
		
	ElsIf EstimateTime = 100 Then
		
		Form.Items.DecodingTheRatioOfCriteria.Title = NStr("vi = 'Đánh giá hiện tại: tiêu chí duy nhất được tính đến - giảm thời hạn phát hành.';
															|ru = 'Текущая оценка: учитывается единственный критерий - сокращение срока выпуска.';
															|en = 'Current evaluation: one criterion is considered - release time reduction.'; fa = 'Current evaluation: one criterion is considered - release time reduction.';
															|it = 'Valutazione attuale: l''unico criterio è preso in considerazione è la riduzione del periodo di rilascio.';
															|pl = 'Bieżąca ocena: jest uwzględniane tylko jedno kryterium - skrócenie terminu wypuszczenia produkcji.';
															|tr = 'Mevcut değerlendirme: Tek kriter dikkate alınır; ürün çıkış süresinin kısaltılması.'");
		
	ElsIf EstimateCost = 100 Then
		
		Form.Items.DecodingTheRatioOfCriteria.Title = NStr("vi = 'Đánh giá hiện tại: tiêu chí duy nhất được tính đến - giảm chi phí của lịch trình.';
															|ru = 'Текущая оценка: учитывается единственный критерий - сокращение стоимости расписания.';
															|en = 'Current evaluation: one criterion is considered - timetable cost reduction.'; fa = 'Current evaluation: one criterion is considered - timetable cost reduction.';
															|it = 'Valutazione attuale: l''unico criterio preso in considerazione è la riduzione del costo del programma.';
															|pl = 'Bieżąca ocena: jest uwzględniane tylko jedno kryterium - zmniejszenie kosztów harmonogramu.';
															|tr = 'Mevcut değerlendirme: Tek kriter dikkate alınır; çizelge maliyetinin azaltılması.'");
		
	Else
		
		Form.Items.DecodingTheRatioOfCriteria.Title = 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đánh giá liên tục: tầm quan trọng của việc rút ngắn thời hạn sản xuất liên quan đến việc giảm chi phí của lịch trình được xác định bởi tỷ lệ %1% đến %2%.';
					|ru = 'Текущая оценка: значимость сокращения срока выпуска по отношению к сокращению стоимости расписания определяется соотношением %1% к %2%.';
					|en = 'Current evaluation: significance of release time reduction against the timetable cost reduction is determined by ratio %1% to %2%.'; fa = 'Current evaluation: significance of release time reduction against the timetable cost reduction is determined by ratio %1% to %2%.';
					|it = 'Valutazione attuale: l''importanza di ridurre il periodo di rilascio in relazione alla riduzione del costo del programma è determinata dal rapporto di %1% con %2%.';
					|pl = 'Bieżąca ocena: wartość skrócenia terminu wypuszczenia produkcji odnośnie zmniejszenia kosztów harmonogramu jest wyrażana w stosunku %1% do %2%.';
					|tr = 'Mevcut değerlendirme: Ürün çıkış süresinin kısaltılmasının, çizelge maliyetinin azaltılmasına göre önemi, %1% ile %2% oranında belirlenmektedir.'"),
				Format(EstimateTime, "ND=3"),
				Format(EstimateCost, "ND=3"));
				
	EndIf;
	
EndProcedure

#EndRegion
