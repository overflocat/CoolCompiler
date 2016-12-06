# 扩展要求-实验报告

以下部分是对扩展要求4.1问题的回答。除了分析对现有checker的不足之外，我（们）也对现有的checker做了一些改进，可见后文说明。这次试验是我和张艺潇（PB14011008）共同完成的，所以我们提交的Checker对应的代码是完全一致的，但是提交的实验报告和测试用例是独立的。

## 问题回答

1. 除了这些缺陷以外，clang静态分析器还有哪些缺陷？

- 答：在http://clang-analyzer.llvm.org/open_projects.html还提到了一些缺陷，例如不能很好地处理c++的临时变量，不能精确地处理c++中的new和delete，不能精确地处理动态类型转换等等。这些主要都是analyzer的问题。

2. 以动态内存、或文件等资源有关的缺陷检查为例，对clang 静态分析器进行如下使用和分析工作：

   1. 是否能检查该类缺陷？

   - 答：由于这次实验的主要目标是StreamChecker，因此本题和之后的题目都主要分析这个Checker。StreamChecker能够检查的缺陷是双重关闭，文件指针泄漏，和文件指针是否出现打开失败的现象，这一部分和SimpleStreamChecker基本一致。另外，StreamChecker还能检测更多相关的函数，以及`fseek`中可能存在的参数错误。

   2. 检查能力到什么程度（程序存在哪些特征时检查不出来）？

   - 答：StreamChecker的检查能力较SimpleStreamChecker较强，比如说在以下的情况：

     ```c
     FILE *a = fopen("a.txt", "w");
     fclose(a+1);
     ```

     SimpleStreamChecker是检查不出该类错误的，但StreamChecker可以。当然除此之外，对于analyzer具有的缺陷，用StreamChecker检查时一样会有，比如不能处理多重循环，不能处理浮点数条件，不能处理位运算等。

   3. 检查的实现机制是什么？列出相关的源码位置和主要处理流程。

   - 答：对于双重关闭：

     ```cpp
     ProgramStateRef StreamChecker::CheckDoubleClose(const CallExpr *CE,
                                                    ProgramStateRef state,
                                                    CheckerContext &C) const {
       SymbolRef Sym =
         state->getSVal(CE->getArg(0), C.getLocationContext()).getAsSymbol();
       if (!Sym)
         return state;

       const StreamState *SS = state->get<StreamMap>(Sym);

       // If the file stream is not tracked, return.
       if (!SS)
         return state;

       // Check: Double close a File Descriptor could cause undefined behaviour.
       // Conforming to man-pages
       if (SS->isClosed()) {
         ExplodedNode *N = C.generateErrorNode();
         if (N) {
           if (!BT_doubleclose)
             BT_doubleclose.reset(new BuiltinBug(
                 this, "Double fclose", "Try to close a file Descriptor already"
                                        " closed. Cause undefined behaviour."));
           C.emitReport(llvm::make_unique<BugReport>(
               *BT_doubleclose, BT_doubleclose->getDescription(), N));
         }
         return nullptr;
       }
     ```

     这个函数主要作用是取fclose()的第一个参数，并在StreamMap中寻找它对应的状态。如果这个流已经被关闭，那么就报告DoubleClose。

     对于指针泄漏：

     ```cpp
     void StreamChecker::checkDeadSymbols(SymbolReaper &SymReaper,
                                          CheckerContext &C) const {
       // TODO: Clean up the state.
       for (SymbolReaper::dead_iterator I = SymReaper.dead_begin(),
              E = SymReaper.dead_end(); I != E; ++I) {
         SymbolRef Sym = *I;
         ProgramStateRef state = C.getState();
         const StreamState *SS = state->get<StreamMap>(Sym);
         if (!SS)
           continue;

         if (SS->isOpened()) {
           ExplodedNode *N = C.generateErrorNode();
           if (N) {
             if (!BT_ResourceLeak)
               BT_ResourceLeak.reset(new BuiltinBug(
                   this, "Resource Leak",
                   "Opened File never closed. Potential Resource leak."));
             C.emitReport(llvm::make_unique<BugReport>(
                 *BT_ResourceLeak, BT_ResourceLeak->getDescription(), N));
           }
         }
       }
     }
     ```

     它会去寻找所有已经超出作用范围（dead）的Symbol，并且依次去检查它们是否在StreamMap里有对应的状态。如果有并且状态是open，则报告指针泄漏。

     对于文件指针为空：

     ```cpp
     ProgramStateRef StreamChecker::CheckNullStream(SVal SV, ProgramStateRef state,
                                         CheckerContext &C) const {
       Optional<DefinedSVal> DV = SV.getAs<DefinedSVal>();
       if (!DV)
         return nullptr;

       ConstraintManager &CM = C.getConstraintManager();
       ProgramStateRef stateNotNull, stateNull;
       std::tie(stateNotNull, stateNull) = CM.assumeDual(state, *DV);

       if (!stateNotNull && stateNull) {
         if (ExplodedNode *N = C.generateErrorNode(stateNull)) {
           if (!BT_nullfp)
             BT_nullfp.reset(new BuiltinBug(this, "NULL stream pointer",
                                            "Stream pointer might be NULL."));
           C.emitReport(llvm::make_unique<BugReport>(
               *BT_nullfp, BT_nullfp->getDescription(), N));
         }
         return nullptr;
       }
       return stateNotNull;
     }
     ```

     这里去取函数参数对应的Sval，并且依次检查和它相关的stateNotNull和stateNull状态，如果StateNull状态存在的话，则报告该指针可能为空。

     另外还有对fseek的检测：

     ```cpp
     void StreamChecker::Fseek(CheckerContext &C, const CallExpr *CE) const {
       ProgramStateRef state = C.getState();
       if (!(state = CheckNullStream(state->getSVal(CE->getArg(0),
                                                    C.getLocationContext()), state, C)))
         return;
       // Check the legality of the 'whence' argument of 'fseek'.
       SVal Whence = state->getSVal(CE->getArg(2), C.getLocationContext());
       Optional<nonloc::ConcreteInt> CI = Whence.getAs<nonloc::ConcreteInt>();

       if (!CI)
         return;

       int64_t x = CI->getValue().getSExtValue();
       if (x >= 0 && x <= 2)
         return;

       if (ExplodedNode *N = C.generateNonFatalErrorNode(state)) {
         if (!BT_illegalwhence)
           BT_illegalwhence.reset(
               new BuiltinBug(this, "Illegal whence argument",
                              "The whence argument to fseek() should be "
                              "SEEK_SET, SEEK_END, or SEEK_CUR."));
         C.emitReport(llvm::make_unique<BugReport>(
             *BT_illegalwhence, BT_illegalwhence->getDescription(), N));
       }
     }
     ```

     这里主要是检测fseek()的参数是不是指定的类型，不是的话则产生一个BugReport。

     比较奇怪的是，这里相较SimpleStreamChecker，没有对PointerEscape的检测。

## 对现有checker的改进

除了以上的分析之外，现有的StreamChecker其实并不完善，有很多可以改进的地方，比如说它存在如下的缺陷：

1. 对c标准库中的函数支持不完全，例如StreamChecker中提供了对fwrite和fread的参数检查，但是对于fprintf和fscanf之类的函数则没有涉及。另外，StreamChecker中对freopen函数并没有相应的支持，而这个函数是能够改变流的，这可能在某些情况下会略去一些错误。

2. 不能够检测是否打开的是同一个文件，例如对如下的例子：

   ```cpp
   FILE *fp1 = fopen( "a.txt", "w" );
   FILE *fp2 = fopen( "a.txt", "w" );
   //do someting
   fclose( fp1 );
   fclose( fp2 );
   ```

   分析器并不会报告任何warning。

3. 不能判断函数的操作数是否有意义，在某些明显错误的情况下应该能够给出提示，例如如下的情况：

   ```cpp
   FILE *fp = fopen( "a.txt"， "w" );
   //do something
   fclose( fp );
   fprintf( fp, "aa" );
   ```

   分析器并不会报告任何warning。

4. FILE和文件句柄号混用的时候无法正确检测；

5. 不能判断打开流的类型，以及报告对应的错误，例如对于如下的情况：

   ```cpp
   FILE *fp = fopen( "a.txt", "r" );
   fprintf( fp, "aa" );
   fclose( fp );
   ```

   往一个输入流里写字符显然不能达到预期的效果，但是分析器不会报任何warning。

本次实验我（们）主要是针对第一点和第五点，对checker做了对应的修改。在目前的框架上也能比较容易地实现对函数操作数的检测，只要在StreamChecker::CheckInconsistency函数里加上对Sval对应Stream是否已经close就可以实现这个功能，但是由于编译的时间过长以及本次实验的时间比较紧张，所以并没有完成。

以下是对代码的说明，我（们）这次做的主要改进有：

1. 添加了对标准库中大部分函数的支持，例如StreamChekcer中没有的fscanf，fprintf，fgetc，fputc，fgets，fputs等。这一部分较为简单由于不同函数需要检测部分的区别不大，只需要依次添加即可。添加的函数如下：（CheckInconsistency函数将在之后说明）

   ```cpp
   void StreamChecker::Fputs(CheckerContext &C, const CallExpr *CE) const {
     ProgramStateRef state = C.getState();
     if (!CheckNullStream(state->getSVal(CE->getArg(1), C.getLocationContext()),
                          state, C))
       return;
     CheckInconsistency(state, C, CE, 1， StreamState::Write);
   }
   ```

2. 添加了对fopen的支持。函数如下：

   ```cpp
   void StreamChecker::Freopen(CheckerContext &C, const CallExpr *CE) const {
     ProgramStateRef state = C.getState();
     if (!CheckNullStream(state->getSVal(CE->getArg(2), C.getLocationContext()),
                          state, C))
       return;

     StreamState:: Mode m;
     const StringLiteral *strArg = 
         dyn_cast<StringLiteral>(CE->getArg(1)->IgnoreParenImpCasts());
     if(strArg) {
       StringRef OpenMode = strArg->getString();
       if(OpenMode.back() == '+')
         m = StreamState::Both;
       else{
         if(OpenMode.front() == 'w' || OpenMode.front() == 'a')
           m = StreamState::Write;
         else if(OpenMode.front() == 'r')
           m = StreamState::Read;
         else{
           m = StreamState::Both;
         }
       }
     }
     
     SymbolRef Sym =
       state->getSVal(CE->getArg(2), C.getLocationContext()).getAsSymbol();
     if (!Sym)
       return;

     const StreamState *SS = state->get<StreamMap>(Sym);
     if (!SS)
       return;

     state->set<StreamMap>(Sym, StreamState::getOpened(CE, m));
     if (state)
       C.addTransition(state);
   }
   ```

   首先检测输入的Sval对应的Stream是否为空，如果是的话则报错。然后根据函数的参数，去改变该流对应的读/写状态，并返回相应的state。

3. 添加了对打开流类型的判断。这主要包括三个部分：

   1. 在StreamState中声明一个新的枚举类型Mode，用它来区分当前的流的读写状态。然后往类的构造函数中相应的添加该枚举类型，并且相应地修改getopened等函数。

   2. 往OpenFileAux中添加一部分，这一部分在上述提及的Freopen函数中也有出现：

      ```cpp
      StreamState:: Mode m;
        const StringLiteral *strArg = 
            dyn_cast<StringLiteral>(CE->getArg(1)->IgnoreParenImpCasts());
        if(strArg) {
          StringRef OpenMode = strArg->getString();
          if(OpenMode.back() == '+')
            m = StreamState::Both;
          else{
            if(OpenMode.front() == 'w' || OpenMode.front() == 'a')
              m = StreamState::Write;
            else if(OpenMode.front() == 'r')
              m = StreamState::Read;
            else{
              m = StreamState::Both;
            }
          }
        }
      ```

      m是之后要传给构造函数的值。这一部分取函数的第二个参数，并且将其转化为’字符串‘类型，然后根据字符串的内容（比如第一个字符是r或者w）来去判断当前打开的流对应的状态是读、写或者是读/写，并且生成相应的m。

   3. 构造一个新的函数StreamChecker::CheckInconsistency，如下：

      ```cpp
      void StreamChecker::CheckInconsistency(ProgramStateRef state,
                                             CheckerContext &C,
                                             const CallExpr *CE,
                                             unsigned argIndex,
                                             StreamState::Mode m) const {
        SymbolRef Sym =
            state->getSVal(CE->getArg(argIndex), C.getLocationContext()).getAsSymbol();
        if(!Sym)
          return;
        const StreamState *SS = state->get<StreamMap>(Sym);
        if(!SS)
          return;
        if (SS->M != m && SS->M != StreamState::Both ){
          ExplodedNode *N = C.generateErrorNode();
          if (N) {
            if (!BT_InconsistentIO)
               BT_InconsistentIO.reset(new BuiltinBug(
                    this, "Inconsistent IO",
                    "Read/Write behavior is inconsistent with declare."));
            C.emitReport(llvm::make_unique<BugReport>(
                *BT_InconsistentIO, BT_InconsistentIO->getDescription(), N));
          }
        }
      }
      ```

      这个函数根据传入参数的位置，去取相应参数，并在StreamMap中寻找其对应的流。如果对应的流中Mode的类型和传入参数StreamState::Mode m不匹配，那么则产生一个BugReport。

   在编写时遇到的主要困难是clang的编译耗时过久，而且尝试使用Release版本发现可能会导致一些与Debug版本不一致的行为，暂不清楚是什么原因导致的。另外还遇到了一个问题，就是我所做的一些检测实在MacOS下调用clang进行的检测，比如对于下列的代码：

   ```cpp
   FILE *fp = fopen( "a.txt", "w" );
   fprintf( fp, "aa" );
   fclose( fp );
   ```

   用MacOS所带的clang的静态分析器进行检测并不会产生任何warning。但是相同的代码用助教所给的clang版本进行编译，产生的静态分析器会报告fp可能为NULL。我已开始以为我（们）修改的静态分析器产生了一些问题，才会报告这个warning，直到最后我把原始文件放回工程中重新编译，才发现这是一个feature……在这个问题上浪费了不少时间。

   ​