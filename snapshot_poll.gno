package snapshot_poll

import (
	"std"
	"strconv"
	"strings"
)

// Poll represents a single yes/no/abstain poll with a deadline.
type Poll struct {
	ID       int
	Creator  string
	Question string
	Deadline int64 // block height or Unix timestamp
	Yes      []string
	No       []string
	Abstain  []string
	Closed   bool
}

var (
	polls  []*Poll
	nextID int
)

func init() {
	polls = []*Poll{}
	nextID = 0
}

func caller() string {
	return string(std.PreviousRealm().Address())
}

// ---------- helpers ----------

func mustGetPoll(pollID int) *Poll {
	if pollID < 0 || pollID >= len(polls) {
		panic("poll not found: " + strconv.Itoa(pollID))
	}
	return polls[pollID]
}

func hasVoted(p *Poll, voter string) bool {
	for _, v := range p.Yes {
		if v == voter {
			return true
		}
	}
	for _, v := range p.No {
		if v == voter {
			return true
		}
	}
	for _, v := range p.Abstain {
		if v == voter {
			return true
		}
	}
	return false
}

// ---------- write operations ----------

// CreatePoll creates a new poll. The caller becomes the creator.
func CreatePoll(_ realm, question string, deadline int64) string {
	if strings.TrimSpace(question) == "" {
		panic("question must not be empty")
	}
	if deadline <= 0 {
		panic("deadline must be positive")
	}

	id := nextID
	nextID++

	polls = append(polls, &Poll{
		ID:       id,
		Creator:  caller(),
		Question: question,
		Deadline: deadline,
	})
	return "poll_" + strconv.Itoa(id)
}

// Vote casts a vote on a poll. Choice must be "yes", "no", or "abstain".
// Each address may only vote once per poll.
func Vote(_ realm, pollID int, choice string, now int64) {
	p := mustGetPoll(pollID)
	if p.Closed {
		panic("poll is closed")
	}
	if now > p.Deadline {
		panic("poll deadline has passed")
	}

	voter := caller()
	if hasVoted(p, voter) {
		panic("already voted")
	}

	switch strings.ToLower(choice) {
	case "yes":
		p.Yes = append(p.Yes, voter)
	case "no":
		p.No = append(p.No, voter)
	case "abstain":
		p.Abstain = append(p.Abstain, voter)
	default:
		panic("choice must be yes, no, or abstain")
	}
}

// ClosePoll stops a poll from accepting further votes. Only the creator
// can close it.
func ClosePoll(_ realm, pollID int) {
	p := mustGetPoll(pollID)
	if p.Creator != caller() {
		panic("only the creator can close this poll")
	}
	if p.Closed {
		panic("poll is already closed")
	}
	p.Closed = true
}

// ---------- read-only queries ----------

// GetResults returns a summary of a poll's votes.
func GetResults(pollID int) string {
	p := mustGetPoll(pollID)
	total := len(p.Yes) + len(p.No) + len(p.Abstain)
	status := "open"
	if p.Closed {
		status = "closed"
	}

	var b strings.Builder
	b.WriteString("Poll #" + strconv.Itoa(p.ID) + " [" + status + "]\n")
	b.WriteString("Question: " + p.Question + "\n")
	b.WriteString("Creator: " + p.Creator + "\n")
	b.WriteString("Yes: " + strconv.Itoa(len(p.Yes)) + "\n")
	b.WriteString("No: " + strconv.Itoa(len(p.No)) + "\n")
	b.WriteString("Abstain: " + strconv.Itoa(len(p.Abstain)) + "\n")
	b.WriteString("Total: " + strconv.Itoa(total) + "\n")
	return b.String()
}

// ListActivePolls returns IDs of all open polls.
func ListActivePolls() string {
	var ids []string
	for _, p := range polls {
		if !p.Closed {
			ids = append(ids, strconv.Itoa(p.ID))
		}
	}
	if len(ids) == 0 {
		return "none"
	}
	return strings.Join(ids, ", ")
}

// ---------- render ----------

// Render returns a markdown overview. Never panics.
func Render(path string) string {
	if len(polls) == 0 {
		return "# Snapshot Poll\n\nNo polls created.\n"
	}

	var b strings.Builder
	b.WriteString("# Snapshot Poll\n\n")
	b.WriteString("**Total polls:** " + strconv.Itoa(len(polls)) + "\n\n")

	for _, p := range polls {
		status := "open"
		if p.Closed {
			status = "closed"
		}
		total := len(p.Yes) + len(p.No) + len(p.Abstain)

		b.WriteString("### Poll #" + strconv.Itoa(p.ID) + " [" + status + "]\n\n")
		b.WriteString("**Question:** " + p.Question + "\n\n")
		b.WriteString("**Creator:** `" + p.Creator + "`\n\n")
		b.WriteString("| Yes | No | Abstain | Total |\n")
		b.WriteString("|-----|-----|---------|-------|\n")
		b.WriteString("| " + strconv.Itoa(len(p.Yes)) + " | " + strconv.Itoa(len(p.No)) +
			" | " + strconv.Itoa(len(p.Abstain)) + " | " + strconv.Itoa(total) + " |\n\n")
	}
	return b.String()
}
