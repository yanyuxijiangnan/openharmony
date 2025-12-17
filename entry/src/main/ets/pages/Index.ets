import promptAction from '@ohos.promptAction';

// ========================== 补充所有缺失的接口（约束所有返回类型）==========================
interface ScaleOption {
  x: number;
  y: number;
}
interface TextOverflowOption {
  overflow: TextOverflow;
}
interface VerticalAlignRule {
  anchor: string;
  align: VerticalAlign;
}
interface HorizontalAlignRule {
  anchor: string;
  align: HorizontalAlign;
}
interface KeyItem {
  text: string;
  type: 'number' | 'operator' | 'function';
  id: string;
}
interface BtnStyle {
  backgroundColor: string;
  fontColor: string;
  scale: ScaleOption;
}
interface ComponentAlignRules {
  top?: VerticalAlignRule;
  bottom?: VerticalAlignRule;
  left?: HorizontalAlignRule;
  right?: HorizontalAlignRule;
  width?: string;
}
// 新增：约束表达式解析结果类型（解决对象字面量类型声明错误）
interface ExpressionParseResult {
  numbers: number[];
  operators: string[];
}
// 新增：约束高优先级计算结果类型（解决未声明对象字面量错误）
interface HighPriorityResult {
  nums: number[];
  ops: string[];
}

@Entry
@Component
struct Index {
  @State inputStr: string = '';
  @State resultStr: string = '';

  private readonly numBtnColor: string = '#f0f0f0';
  private readonly opBtnColor: string = '#ff9500';
  private readonly funcBtnColor: string = '#dcdcdc';
  private readonly textColor: string = '#000000';
  private readonly opTextColor: string = '#ffffff';
  private isPressed: string = '';

  private readonly keyList: KeyItem[] = [
    { text: 'C', type: 'function', id: 'btnC' },
    { text: 'Del', type: 'function', id: 'btnDel' },
    { text: '%', type: 'operator', id: 'btnPercent' },
    { text: '/', type: 'operator', id: 'btnDiv' },
    { text: '7', type: 'number', id: 'btn7' },
    { text: '8', type: 'number', id: 'btn8' },
    { text: '9', type: 'number', id: 'btn9' },
    { text: '*', type: 'operator', id: 'btnMul' },
    { text: '4', type: 'number', id: 'btn4' },
    { text: '5', type: 'number', id: 'btn5' },
    { text: '6', type: 'number', id: 'btn6' },
    { text: '-', type: 'operator', id: 'btnSub' },
    { text: '1', type: 'number', id: 'btn1' },
    { text: '2', type: 'number', id: 'btn2' },
    { text: '3', type: 'number', id: 'btn3' },
    { text: '+', type: 'operator', id: 'btnAdd' },
    { text: '0', type: 'number', id: 'btn0' },
    { text: '.', type: 'number', id: 'btnDot' },
    { text: '=', type: 'operator', id: 'btnEqual' },
  ];

  // ========================== 按键点击处理（无变化）==========================
  private handleKeyClick(key: string): void {
    this.isPressed = key;
    setTimeout(() => {
      this.isPressed = '';
    }, 100);

    switch (key) {
      case 'C':
        this.inputStr = '';
        this.resultStr = '';
        break;
      case 'Del':
        this.inputStr = this.inputStr.slice(0, -1);
        this.calculateResult();
        break;
      case '=':
        this.calculateResult(true);
        break;
      default:
        const lastChar = this.inputStr.slice(-1);
        const isOp = ['+', '-', '*', '/', '%'].includes(key);
        if (isOp && (this.inputStr === '' || ['+', '-', '*', '/', '%'].includes(lastChar))) {
          promptAction.showToast({ message: '输入格式错误', duration: 1000 });
          return;
        }
        if (key === '.' && this.inputStr.split(/[\+\-\*\/\%]/).pop()?.includes('.')) {
          promptAction.showToast({ message: '已包含小数点', duration: 1000 });
          return;
        }
        this.inputStr += key;
        this.calculateResult();
        break;
    }
  }

  // ========================== 核心计算逻辑（移除解构赋值，用接口约束返回值）==========================
  private calculateResult(isFinal: boolean = false): void {
    if (this.inputStr === '') {
      this.resultStr = '';
      return;
    }

    try {
      // 修复1：移除解构赋值，分开获取结果（ArkTS不支持解构）
      const parseResult: ExpressionParseResult = this.parseExpression(this.inputStr);
      const numbers: number[] = parseResult.numbers;
      const operators: string[] = parseResult.operators;

      // 修复2：移除数组解构，用接口约束返回值
      const highPriorityRes: HighPriorityResult = this.processHighPriority(numbers, operators);
      const nums: number[] = highPriorityRes.nums;
      const ops: string[] = highPriorityRes.ops;

      // 计算加减
      let result = nums[0];
      for (let i = 0; i < ops.length; i++) {
        switch (ops[i]) {
          case '+':
            result += nums[i + 1];
            break;
          case '-':
            result -= nums[i + 1];
            break;
        }
      }

      // 结果格式化
      const formatResult: string = Number.isInteger(result)
        ? result.toString()
        : result.toFixed(6).replace(/\.?0*$/, '');

      if (isFinal) {
        this.inputStr = formatResult;
        this.resultStr = '';
      } else {
        this.resultStr = `= ${formatResult}`;
      }
    } catch (error) {
      this.resultStr = '格式错误';
    }
  }

  // 解析表达式（返回值用接口约束）
  private parseExpression(expr: string): ExpressionParseResult {
    const result: ExpressionParseResult = { numbers: [], operators: [] };
    let currentNum = '';

    for (const char of expr) {
      if (['+', '-', '*', '/', '%'].includes(char)) {
        result.numbers.push(parseFloat(currentNum));
        currentNum = '';
        result.operators.push(char);
      } else {
        currentNum += char;
      }
    }
    result.numbers.push(parseFloat(currentNum));
    return result;
  }

  // 处理高优先级运算（返回值用接口约束，避免未声明对象）
  private processHighPriority(numbers: number[], operators: string[]): HighPriorityResult {
    const nums: number[] = [...numbers];
    const ops: string[] = [...operators];

    let i = 0;
    while (i < ops.length) {
      if (['*', '/', '%'].includes(ops[i])) {
        const a = nums[i];
        const b = nums[i + 1];
        let res: number;
        switch (ops[i]) {
          case '*':
            res = a * b;
            break;
          case '/':
            res = b === 0 ? 0 : a / b; // 避免除零错误
            break;
          case '%':
            res = a % b;
            break;
          default:
            res = 0;
        }
        nums.splice(i, 2, res);
        ops.splice(i, 1);
      } else {
        i++;
      }
    }

    // 显式返回接口类型
    return { nums: nums, ops: ops } as HighPriorityResult;
  }

  // ========================== 其他方法（无变化）==========================
  private getBtnStyle(type: 'number' | 'operator' | 'function', key: string): BtnStyle {
    return {
      backgroundColor: type === 'number' ? this.numBtnColor :
        type === 'operator' ? this.opBtnColor : this.funcBtnColor,
      fontColor: type === 'operator' ? this.opTextColor : this.textColor,
      scale: this.isPressed === key ? { x: 0.95, y: 0.95 } as ScaleOption : { x: 1, y: 1 } as ScaleOption
    } as BtnStyle;
  }

  private getBtnAlignRules(keyId: string): ComponentAlignRules {
    switch (keyId) {
      case 'btnC':
        return {
          left: { anchor: '__container__', align: HorizontalAlign.Start } as HorizontalAlignRule,
          bottom: { anchor: 'btn7', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btnDel':
        return {
          left: { anchor: 'btnC', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn7', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btnPercent':
        return {
          left: { anchor: 'btnDel', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn7', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btnDiv':
        return {
          left: { anchor: 'btnPercent', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn7', align: VerticalAlign.Top } as VerticalAlignRule,
          right: { anchor: '__container__', align: HorizontalAlign.End } as HorizontalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btn7':
        return {
          left: { anchor: '__container__', align: HorizontalAlign.Start } as HorizontalAlignRule,
          bottom: { anchor: 'btn4', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btn8':
        return {
          left: { anchor: 'btn7', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn4', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btn9':
        return {
          left: { anchor: 'btn8', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn4', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btnMul':
        return {
          left: { anchor: 'btn9', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn4', align: VerticalAlign.Top } as VerticalAlignRule,
          right: { anchor: '__container__', align: HorizontalAlign.End } as HorizontalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btn4':
        return {
          left: { anchor: '__container__', align: HorizontalAlign.Start } as HorizontalAlignRule,
          bottom: { anchor: 'btn1', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btn5':
        return {
          left: { anchor: 'btn4', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn1', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btn6':
        return {
          left: { anchor: 'btn5', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn1', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btnSub':
        return {
          left: { anchor: 'btn6', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn1', align: VerticalAlign.Top } as VerticalAlignRule,
          right: { anchor: '__container__', align: HorizontalAlign.End } as HorizontalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btn1':
        return {
          left: { anchor: '__container__', align: HorizontalAlign.Start } as HorizontalAlignRule,
          bottom: { anchor: 'btn0', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btn2':
        return {
          left: { anchor: 'btn1', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn0', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btn3':
        return {
          left: { anchor: 'btn2', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn0', align: VerticalAlign.Top } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btnAdd':
        return {
          left: { anchor: 'btn3', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: 'btn0', align: VerticalAlign.Top } as VerticalAlignRule,
          right: { anchor: '__container__', align: HorizontalAlign.End } as HorizontalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btn0':
        return {
          left: { anchor: '__container__', align: HorizontalAlign.Start } as HorizontalAlignRule,
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom } as VerticalAlignRule,
          width: '46%'
        } as ComponentAlignRules;
      case 'btnDot':
        return {
          left: { anchor: 'btn0', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom } as VerticalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      case 'btnEqual':
        return {
          left: { anchor: 'btnDot', align: HorizontalAlign.End } as HorizontalAlignRule,
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom } as VerticalAlignRule,
          right: { anchor: '__container__', align: HorizontalAlign.End } as HorizontalAlignRule,
          width: '22%'
        } as ComponentAlignRules;
      default:
        return {} as ComponentAlignRules;
    }
  }

  build() {
    RelativeContainer() {
      Column() {
        Text(this.inputStr)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.End)
          .padding({ top: 16, right: 16, bottom: 8, left: 16 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis } as TextOverflowOption)

        Text(this.resultStr)
          .fontSize(24)
          .fontColor('#666666')
          .textAlign(TextAlign.End)
          .padding({ top: 8, right: 16, bottom: 16, left: 16 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis } as TextOverflowOption)
      }
      .id('displayArea')
      .width('100%')
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top } as VerticalAlignRule,
        left: { anchor: '__container__', align: HorizontalAlign.Start } as HorizontalAlignRule,
        right: { anchor: '__container__', align: HorizontalAlign.End } as HorizontalAlignRule,
        bottom: { anchor: 'btnC', align: VerticalAlign.Top } as VerticalAlignRule
      } as ComponentAlignRules)
      .backgroundColor('#ffffff')

      ForEach(this.keyList, (item: KeyItem) => {
        Text(item.text)
          .id(item.id)
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .borderRadius(32)
          .padding(8)
          .margin(4)
          .backgroundColor(this.getBtnStyle(item.type, item.text).backgroundColor)
          .fontColor(this.getBtnStyle(item.type, item.text).fontColor)
          .scale(this.getBtnStyle(item.type, item.text).scale)
          .animation({ duration: 100 })
          .onClick(() => this.handleKeyClick(item.text))
          .alignRules(this.getBtnAlignRules(item.id))
      }, (item: KeyItem) => item.id)
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#f8f8f8')
    .padding(8)
  }
}