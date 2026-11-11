
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	Items.Description.MarkIncomplete = False;
	
	If Object.Ref = Catalogs.DiscountsMarkups.RootGroup Then
		Items.Parent.Visible = False;
	EndIf;
	
	OnCreatReadAtServer();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OptionForSharingDiscountsMarkupsOnChange(Item)
	
	UpdateFormElements(ThisForm, LongDesc);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateFormElements(Form, LongDesc)
	
	If Form.Object.JointApplicationOption = PredefinedValue("Enum.OptionsOfJointUsageOfDiscountsAndMarkups.Max") Then
		LongDesc = NStr("vi = 'Đang áp dụng một chiết khấu lớn nhất trong nhóm';
						|ru = 'Применяется одна наибольшая скидка внутри группы';
						|en = 'One biggest inner group discount is applied'; fa = 'One biggest inner group discount is applied';
						|it = 'Viene applicato lo sconto maggiore all''interno del gruppo';
						|pl = 'Jest stosowany jeden największy rabat wewnątrz grupy';
						|tr = 'Grup içindeki en büyük olan tek indirim uygulanır'");
		Form.Items.OptionOfJointApplicationResultCalculation.Visible = True;
	ElsIf Form.Object.JointApplicationOption = PredefinedValue("Enum.OptionsOfJointUsageOfDiscountsAndMarkups.Min") Then
		LongDesc = NStr("vi = 'Đang áp dụng một chiết khấu nhỏ nhất trong nhóm';
						|ru = 'Применяется одна наименьшая скидка внутри группы';
						|en = 'One smallest inner group discount is applied'; fa = 'One smallest inner group discount is applied';
						|it = 'Viene applicato lo sconto minore all''interno del gruppo';
						|pl = 'Jest stosowany jeden najmniejszy rabat wewnątrz grupy';
						|tr = 'Grup içindeki en küçük olan tek indirim uygulanır'");
		Form.Items.OptionOfJointApplicationResultCalculation.Visible = True;
	ElsIf Form.Object.JointApplicationOption = PredefinedValue("Enum.OptionsOfJointUsageOfDiscountsAndMarkups.Exclusion") Then
		LongDesc = NStr("vi = 'Khi sử dụng chung nhiều chiết khấu (phụ thu) trong một nhóm thì chương trình sẽ chỉ kích hoạt chiết khấu có mức ưu tiên cao nhất trong nhóm';
						|ru = 'При совместном действии скидок (наценок) в одной группе будет действовать только та скидка, которая имеет наивысший приоритет в группе';
						|en = 'When there are discounts (markups) used together in one group, only that discount will be valid which has the highest priority in the group'; fa = 'When there are discounts (markups) used together in one group, only that discount will be valid which has the highest priority in the group';
						|it = 'In caso di azione congiunta di sconti (sovrapprezzi) in un gruppo, sarà valido solo tale sconto, che ha la massima priorità nel gruppo';
						|pl = 'Przy wspólnym działaniu rabatów (marż) w jednej grupie będzie obowiązywać tylko ten rabat, który posiada najwyższy priorytet w grupie';
						|tr = 'Aynı gruptaki indirimler (zamlar) birlikte uygulandığında, sadece gruptaki en yüksek önceliğe sahip olan indirim geçerli olacaktır'");
		Form.Items.OptionOfJointApplicationResultCalculation.Visible = True;
	ElsIf Form.Object.JointApplicationOption = PredefinedValue("Enum.OptionsOfJointUsageOfDiscountsAndMarkups.Addition") Then
		LongDesc = NStr("vi = 'Đang áp dụng số tiền của tất cả chiết khấu trong nhóm';
						|ru = 'Применяется сумма всех скидок внутри группы';
						|en = 'Amount of all inner group discounts is applied'; fa = 'Amount of all inner group discounts is applied';
						|it = 'Viene applicata la somma di tutti gli sconti all''interno del gruppo';
						|pl = 'Jest używana suma wszystkich rabatów wewnątrz grupy';
						|tr = 'Grup içindeki tüm indirimlerin tutarı uygulanır'");
		Form.Items.OptionOfJointApplicationResultCalculation.Visible = False;
	ElsIf Form.Object.JointApplicationOption = PredefinedValue("Enum.OptionsOfJointUsageOfDiscountsAndMarkups.Multiplication") Then
		LongDesc = NStr("vi = 'Chiết khấu được áp dụng lần lượt theo trình tự ưu tiên trong nhóm';
						|ru = 'Скидки применяются последовательно в порядке приоритета внутри группы';
						|en = 'Discounts are applied sequentially according to the inner group priority'; fa = 'Discounts are applied sequentially according to the inner group priority';
						|it = 'Gli sconti vengono applicati in modo consecutivo in ordine di priorità all''interno del gruppo';
						|pl = 'Rabaty są stosowane w kolejności priorytetu wewnątrz grupy';
						|tr = 'İndirimler, grup içindeki öncelik düzenine göre sırayla uygulanır'");
		Form.Items.OptionOfJointApplicationResultCalculation.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	UpdateFormElements(ThisForm, LongDesc);
	
EndProcedure

#EndRegion

#EndRegion
