#include <fstream>
#include <iostream>
#include <map>
#include <set>
#include <stack>
#include <string>
#include <vector>

using namespace std;

const string INPUT_FILE_NAME = "input.txt";
const string OUTPUT_FILE_NAME = "output.txt";

set<int> computeEpsilonClosure(set<int> oldStates,
                               vector<map<char, set<int>>> &transitions)
{
    set<int> newStates(oldStates);
    int oldLength = oldStates.size() - 1;

    while (oldLength != newStates.size())
    {
        for (auto state : oldStates)
        {
            if (transitions[state].find(' ') != transitions[state].end())
            {
                for (auto newState : transitions[state][' '])
                {
                    newStates.insert(newState);
                }
            }
        }

        oldLength = oldStates.size();
        oldStates = newStates;
    }

    return newStates;
}

class NfaWithEpsilon
{
  public:
    //  The first state is assumed to be the starting state and the last as the
    //  final state
    int stateCount;
    // For epsilon transitions, the char used is ' ' (space)
    vector<map<char, set<int>>> transitions;

    NfaWithEpsilon()
    {
        stateCount = 0;
    }

    NfaWithEpsilon(char c)
    {
        stateCount = 2;
        map<char, set<int>> transition1{};
        set<int> finalState{};

        finalState.insert(1);
        transition1[c] = finalState;

        map<char, set<int>> transition2{};

        transitions.push_back(transition1);
        transitions.push_back(transition2);
    }

    void printNFA()
    {
        cout << "This NFA has " << stateCount << " states\n";

        for (int i = 0; i < transitions.size(); i++)
        {
            cout << i << ":\n";

            for (auto transition : transitions[i])
            {
                cout << "\t"
                     << ((transition.first == ' ') ? "ep"
                                                   : string{transition.first})
                     << " - {";

                for (auto state = transition.second.begin();
                     state != transition.second.end(); state++)
                {
                    cout << *state;
                    auto copy = state;
                    int distanceFromEnd = 0;
                    while (copy != transition.second.end())
                    {
                        distanceFromEnd++;
                        copy++;
                    }
                    if (distanceFromEnd != 1)
                    {
                        cout << ", ";
                    }
                }

                cout << "}\n";
            }
        }
    }
};

class Nfa
{
  public:
    int stateCount;
    // For epsilon transitions, the char used is ' ' (space)
    vector<map<char, set<int>>> transitions;
    set<int> finalStates;

    Nfa()
    {
        stateCount = 0;
    }

    Nfa(NfaWithEpsilon nfaWithEpsilon, set<char> alphabet)
    {
        stateCount = nfaWithEpsilon.stateCount;
        finalStates.insert(stateCount - 1);

        // Iterate over transitions from all states
        for (int state = 0; state < stateCount; state++)
        {
            map<char, set<int>> newTransitions{};
            set<int> currentState{state};
            set<int> startingStates =
                computeEpsilonClosure(currentState, nfaWithEpsilon.transitions);

            // Iterate over transitions for all input characters (except
            // epsilon) from all of the current states
            for (char symbol : alphabet)
            {
                if (symbol == ' ')
                    continue;

                set<int> newStates;

                for (auto currentStartState : startingStates)
                {
                    if (nfaWithEpsilon.transitions[currentStartState].find(
                            symbol) ==
                        nfaWithEpsilon.transitions[currentStartState].end())
                        continue;

                    for (auto newState :
                         nfaWithEpsilon.transitions[currentStartState][symbol])
                    {
                        newStates.insert(newState);
                    }
                }

                newStates = computeEpsilonClosure(newStates,
                                                  nfaWithEpsilon.transitions);

                if (newStates.size() != 0)
                {
                    newTransitions[symbol] = newStates;
                }
            }

            transitions.push_back(newTransitions);
        }

        // Finally, check if the current start state needs to be a final state

        set<int> startClosure{0};
        startClosure =
            computeEpsilonClosure(startClosure, nfaWithEpsilon.transitions);

        if (startClosure.find(stateCount - 1) != startClosure.end())
        {
            finalStates.insert(0);
        }
    }

    set<int> readInput(string input)
    {
        set<int> currentStates{0};

        for (char c : input)
        {
            set<int> newState;

            for (auto state : currentStates)
            {
                for (int newStates : transitions[state][c])
                {
                    newState.insert(newStates);
                }
            }

            currentStates = newState;
        }

        return currentStates;
    }

    bool checkFinalState(set<int> states)
    {
        for (auto state : states)
        {
            if (finalStates.find(state) != finalStates.end())
            {
                return true;
            }
        }

        return false;
    }

    bool checkAcceptance(string input)
    {
        set<int> finalStates = readInput(input);

        return checkFinalState(finalStates);
    }

    void printNFA()
    {
        cout << "This NFA has " << stateCount << " states\n";

        for (int i = 0; i < transitions.size(); i++)
        {
            cout << i << ":\n";

            for (auto transition : transitions[i])
            {
                cout << "\t" << transition.first << " - {";

                for (auto state = transition.second.begin();
                     state != transition.second.end(); state++)
                {
                    cout << *state;
                    auto copy = state;
                    int distanceFromEnd = 0;
                    while (copy != transition.second.end())
                    {
                        distanceFromEnd++;
                        copy++;
                    }
                    if (distanceFromEnd != 1)
                    {
                        cout << ", ";
                    }
                }

                cout << "}\n";
            }
        }

        cout << "The final states are:\n";
        for (auto state = finalStates.begin(); state != finalStates.end();
             state++)
        {
            cout << *state;

            auto copy = state;
            int distanceFromEnd = 0;
            while (copy != finalStates.end())
            {
                distanceFromEnd++;
                copy++;
            }
            if (distanceFromEnd != 1)
            {
                cout << ", ";
            }
        }
        cout << "\n";
    }
};

string infixToPostfix(string infix)
{
    stack<char> operands;
    string postfix;

    bool concat = false;

    for (auto c : infix)
    {
        if (c == '(')
        {
            if (concat)
            {
                operands.push('.');
            }
            operands.push(c);
            concat = false;
        }
        else if (c == '*' || c == '|')
        {
            operands.push(c);
            concat = false;
        }
        else if (c == ')')
        {
            char stackTop = operands.top();
            operands.pop();
            concat = true;

            while (stackTop != '(')
            {
                postfix.push_back(stackTop);
                stackTop = operands.top();
                operands.pop();
            }
        }
        else
        {
            postfix.push_back(c);
        }
    }

    return postfix;
}

void mergeTransitions(map<char, set<int>> &destination,
                      map<char, set<int>> &source)
{
    // Iterate over all the keys of source
    for (auto sourceIterator = source.begin(); sourceIterator != source.end();
         sourceIterator++)
    {
        // If the key is not present in destination, add it
        if (destination.find(sourceIterator->first) == destination.end())
        {
            destination[sourceIterator->first] = sourceIterator->second;
        }
        else
        {
            // If the key is present in destination, merge the two sets
            for (auto state : sourceIterator->second)
            {
                destination[sourceIterator->first].insert(state);
            }
        }
    }
}

// Plus Operator
void repeatNfa(NfaWithEpsilon &a)
{
    a.transitions[a.stateCount - 1][' '].insert(0);
}

// Question Mark Operator
void optionalNfa(NfaWithEpsilon &a)
{
    a.transitions[0][' '].insert(a.stateCount - 1);
}

NfaWithEpsilon concatenateNfa(NfaWithEpsilon &a, NfaWithEpsilon &b)
{
    NfaWithEpsilon newNfa = NfaWithEpsilon();
    newNfa.stateCount = a.stateCount + b.stateCount - 1;

    for (auto stateTransitions : a.transitions)
    {
        newNfa.transitions.push_back(stateTransitions);
    }

    // Save the transition corresponding to the final state of 'a' and remove it
    // from the vector
    map<char, set<int>> finalStateTransitions = newNfa.transitions.back();
    newNfa.transitions.pop_back();

    for (auto stateTransitions : b.transitions)
    {
        for (auto transition = stateTransitions.begin();
             transition != stateTransitions.end(); transition++)
        {
            set<int> newStates{};

            for (auto state = transition->second.begin();
                 state != transition->second.end(); state++)
            {
                newStates.insert(*state + a.stateCount - 1);
            }

            char key = transition->first;
            stateTransitions.erase(key);
            stateTransitions[key] = newStates;
        }

        newNfa.transitions.push_back(stateTransitions);
    }

    // Merge the transition corresponding to the final state of 'a' with the
    // transition corresponding to the start state of 'b'
    mergeTransitions(newNfa.transitions[a.stateCount - 1],
                     finalStateTransitions);

    return newNfa;
}

NfaWithEpsilon orNfa(NfaWithEpsilon &a, NfaWithEpsilon &b)
{
    NfaWithEpsilon newNfa = NfaWithEpsilon();
    newNfa.stateCount = a.stateCount + b.stateCount;

    for (auto stateTransitions : a.transitions)
    {
        newNfa.transitions.push_back(stateTransitions);
    }

    // Add epsilon transition from the new start state to the start state of b
    map<char, set<int>> startTransition{};
    set<int> startStates{a.stateCount};
    startTransition[' '] = startStates;
    mergeTransitions(newNfa.transitions[0], startTransition);

    for (auto stateTransitions : b.transitions)
    {
        for (auto transition = stateTransitions.begin();
             transition != stateTransitions.end(); transition++)
        {
            set<int> newStates{};

            for (auto state = transition->second.begin();
                 state != transition->second.end(); state++)
            {
                newStates.insert(*state + a.stateCount);
            }

            char key = transition->first;
            stateTransitions.erase(key);
            stateTransitions[key] = newStates;
        }

        newNfa.transitions.push_back(stateTransitions);
    }

    // Add epsilon transition from the end state of a to the new final state
    set<int> newEndTransitionState{newNfa.stateCount - 1};
    map<char, set<int>> newEndTransition1{};
    newEndTransition1[' '] = newEndTransitionState;
    mergeTransitions(newNfa.transitions[a.stateCount - 1], newEndTransition1);

    return newNfa;
}

NfaWithEpsilon closureNfa(NfaWithEpsilon &a)
{
    NfaWithEpsilon newNfa = NfaWithEpsilon();
    newNfa.stateCount = a.stateCount + 2;

    // Add epsilon transitions for the new start state
    map<char, set<int>> startTransition{};
    set<int> startStates{1, a.stateCount + 1};
    startTransition[' '] = startStates;
    newNfa.transitions.push_back(startTransition);

    for (auto stateTransitions : a.transitions)
    {
        for (auto transition = stateTransitions.begin();
             transition != stateTransitions.end(); transition++)
        {
            set<int> newStates{};

            for (auto state : transition->second)
            {
                newStates.insert(state + 1);
            }

            char key = transition->first;
            stateTransitions.erase(key);
            stateTransitions[key] = newStates;
        }

        newNfa.transitions.push_back(stateTransitions);
    }

    // Add epsilon transition from the new final state to the start state
    map<char, set<int>> loopTransition{};
    set<int> loopStates{0};
    loopTransition[' '] = loopStates;
    newNfa.transitions.push_back(loopTransition);

    // Add epsilon transition from the old final state to the new one
    map<char, set<int>> newEndTransition{};
    set<int> newEndTransitionStates{newNfa.stateCount - 1};
    newEndTransition[' '] = newEndTransitionStates;
    mergeTransitions(newNfa.transitions[newNfa.stateCount - 2],
                     newEndTransition);

    return newNfa;
}

bool checkIfRegexAccepts(string regex, string inputString)
{
    string postfixRegex = infixToPostfix(regex);
    stack<NfaWithEpsilon> nfaStack;
    set<char> alphabet{'a', 'b'};

    for (char c : postfixRegex)
    {
        switch (c)
        {
        case '*': {
            NfaWithEpsilon a = nfaStack.top();
            nfaStack.pop();

            nfaStack.push(closureNfa(a));
            break;
        }
        case '|': {
            NfaWithEpsilon b = nfaStack.top();
            nfaStack.pop();

            NfaWithEpsilon a = nfaStack.top();
            nfaStack.pop();

            nfaStack.push(orNfa(a, b));
            break;
        }
        case '.': {
            NfaWithEpsilon b = nfaStack.top();
            nfaStack.pop();

            NfaWithEpsilon a = nfaStack.top();
            nfaStack.pop();

            nfaStack.push(concatenateNfa(a, b));
            break;
        }
        case '+': {
            NfaWithEpsilon a = nfaStack.top();
            nfaStack.pop();

            repeatNfa(a);
            nfaStack.push(a);
            break;
        }
        case '?': {
            NfaWithEpsilon a = nfaStack.top();
            nfaStack.pop();

            optionalNfa(a);
            nfaStack.push(a);
            break;
        }
        default: {
            nfaStack.push(NfaWithEpsilon(c));
            // alphabet.insert(c);
            break;
        }
        }
    }

    NfaWithEpsilon finalNfaWithEpsilon = nfaStack.top();
    nfaStack.pop();

    Nfa finalNfa = Nfa(finalNfaWithEpsilon, alphabet);

    return finalNfa.checkAcceptance(inputString);
}

// code for converting regex to NFA similar to checkIfRegexAccepts
Nfa regexToNfa(string regex)
{
    string postfixRegex = infixToPostfix(regex);
    stack<NfaWithEpsilon> nfaStack;
    set<char> alphabet{'a', 'b'};

    for (char c : postfixRegex)
    {
        switch (c)
        {
        case '*': {
            NfaWithEpsilon a = nfaStack.top();
            nfaStack.pop();

            nfaStack.push(closureNfa(a));
            break;
        }
        case '|': {
            NfaWithEpsilon b = nfaStack.top();
            nfaStack.pop();

            NfaWithEpsilon a = nfaStack.top();
            nfaStack.pop();

            nfaStack.push(orNfa(a, b));
            break;
        }
        case '.': {
            NfaWithEpsilon b = nfaStack.top();
            nfaStack.pop();

            NfaWithEpsilon a = nfaStack.top();
            nfaStack.pop();

            nfaStack.push(concatenateNfa(a, b));
            break;
        }
        case '+': {
            NfaWithEpsilon a = nfaStack.top();
            nfaStack.pop();

            repeatNfa(a);
            nfaStack.push(a);
            break;
        }
        case '?': {
            NfaWithEpsilon a = nfaStack.top();
            nfaStack.pop();

            optionalNfa(a);
            nfaStack.push(a);
            break;
        }
        default: {
            nfaStack.push(NfaWithEpsilon(c));
            break;
        }
        }
    }

    NfaWithEpsilon finalNfaWithEpsilon = nfaStack.top();
    nfaStack.pop();

    return Nfa(finalNfaWithEpsilon, alphabet);
}

struct FileInput
{
    string inputText;
    vector<Nfa> regexps;
};

FileInput parseInput(string filename)
{
    FileInput fileInput;

    ifstream inputFile(filename);
    string line;

    if (inputFile.is_open())
    {
        if (getline(inputFile, line))
        {
            fileInput.inputText = line;
        }
        while (getline(inputFile, line))
        {
            // will only parse non empty lines
            if (!line.empty())
            {
                Nfa temp = regexToNfa(line);
                fileInput.regexps.push_back(temp);
            }
        }
        inputFile.close();
    }
    else
    {
        cout << "Unable to open file" << endl;
    }

    return fileInput;
}

void writeOutput(string contents)
{
    ofstream outputFile(OUTPUT_FILE_NAME);
    if (outputFile.is_open())
    {
        outputFile << contents;
        outputFile.close();
    }
    else
    {
        cout << "Unable to open output file" << endl;
    }
}

int main()
{
    FileInput fileInput = parseInput(INPUT_FILE_NAME);

    int index = 0;
    int inputTextSize = fileInput.inputText.length(),
        regexpsSize = fileInput.regexps.size();
    string output = "";

    while (index < inputTextSize)
    {
        // Calculate longest prefix length for every regex.
        // Keep track of the longest prefix length that is found overall.
        vector<int> prefixLength(regexpsSize, 0);
        int longestPrefixLength = 0;

        for (int i = 0; i < regexpsSize; i++)
        {
            for (int j = index; j < inputTextSize; j++)
            {
                if (fileInput.regexps[i].checkAcceptance(
                        fileInput.inputText.substr(index, j - index + 1)))
                {
                    prefixLength[i] = j - index + 1;
                    if (prefixLength[i] > longestPrefixLength)
                    {
                        longestPrefixLength = prefixLength[i];
                    }
                }
            }
        }

        if (longestPrefixLength == 0)
        {
            // Echo character as longest prefix length is 0.
            output += "<" + fileInput.inputText.substr(index, 1) + ",0>";
            index++;
        }
        else
        {
            // Find the first regex with the longest prefix length.
            int longestPrefixIndex;
            for (int i = 0; i < regexpsSize; i++)
            {
                if (prefixLength[i] == longestPrefixLength)
                {
                    longestPrefixIndex = i + 1;
                    break;
                }
            }

            // Display longest prefix with regex.
            output += "<" +
                      fileInput.inputText.substr(index, longestPrefixLength) +
                      "," + to_string(longestPrefixIndex) + ">";
            index += longestPrefixLength;
        }
    }
    // cout << output << "\n";
    writeOutput(output);

    return 0;
}
