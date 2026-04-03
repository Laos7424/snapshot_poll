package snapshot_poll

import (
	"strconv"
	"strings"

	"gno.land/p/nt/ufmt/v0"
)

// Poll represents a single yes/no/abstain poll with a deadline.
type Poll struct {
	ID       int
	Creator  string
	Question string
	Deadline int64 // Unix timestamp
	Yes      []string
	No       []string
	Abstain  []string
	Closed   bool
}

var (
	polls   []*Poll
	nextID  int
)

// hasVoted checks if an address has already voted in a poll.
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

// CreatePoll creates a new poll with a question and Unix deadline timestamp.
// Returns the poll ID as a string.
func CreatePoll(_ realm, creator, question string, deadline int64) string {
	if strings.TrimSpace(question) == "" {
		return "error: question cannot be empty"
	}
	if deadline <= 0 {
		return "error: deadline must be a positive Unix timestamp"
	}
	p := &Poll{
		ID:       nextID,
		Creator:  creator,
		Question: question,
		Deadline: deadline,
	}
	polls = append(polls, p)
	nextID++
	return ufmt.Sprintf("poll created with id=%d", p.ID)
}

// Vote casts a vote on a poll. Choice must be "yes", "no", or "abstain".
// Each address may only vote once per poll.
func Vote(_ realm, pollID int, voter, choice string, now int64) string {
	if pollID < 0 || pollID >= len(polls) {
		return "error: poll not found"
	}
	p := polls[pollID]
	if p.Closed {
		return "error: poll is closed"
	}
	if now > p.Deadline {
		return "error: poll deadline has passed"
	}
	if hasVoted(p, voter) {
		return "error: address has already voted"
	}
	switch strings.ToLower(choice) {
	case "yes":
		p.Yes = append(p.Yes, voter)
	case "no":
		p.No = append(p.No, voter)
	case "abstain":
		p.Abstain = append(p.Abstain, voter)
	default:
		return "error: choice must be yes, no, or abstain"
	}
	return "vote recorded"
}

// GetResults returns a formatted string with vote counts for a poll.
func GetResults(pollID int) string {
	if pollID < 0 || pollID >= len(polls) {
		return "error: poll not found"
	}
	p := polls[pollID]
	total := len(p.Yes) + len(p.No) + len(p.Abstain)
	return ufmt.Sprintf("poll %d: yes=%d no=%d abstain=%d total=%d closed=%v",
		p.ID, len(p.Yes), len(p.No), len(p.Abstain), total, p.Closed)
}

// ClosePoll manually closes a poll, preventing further votes.
// Only the poll creator may close it.
func ClosePoll(_ realm, pollID int, caller string) string {
	if pollID < 0 || pollID >= len(polls) {
		return "error: poll not found"
	}
	p := polls[pollID]
	if p.Creator != caller {
		return "error: only the creator can close this poll"
	}
	if p.Closed {
		return "error: poll is already closed"
	}
	p.Closed = true
	return ufmt.Sprintf("poll %d closed", p.ID)
}

// ListActivePolls returns a list of all open (non-closed) poll IDs and questions.
func ListActivePolls() string {
	var sb strings.Builder
	found := false
	for _, p := range polls {
		if !p.Closed {
			sb.WriteString(ufmt.Sprintf("id=%d: %s (deadline=%s)\n",
				p.ID, p.Question, strconv.FormatInt(p.Deadline, 10)))
			found = true
		}
	}
	if !found {
		return "no active polls"
	}
	return sb.String()
}

// Render returns a markdown-formatted summary of all polls.
func Render(_ string) string {
	var sb strings.Builder
	sb.WriteString("# Snapshot Poll\n\n")
	if len(polls) == 0 {
		sb.WriteString("No polls have been created yet.\n")
		return sb.String()
	}
	sb.WriteString("## All Polls\n\n")
	for _, p := range polls {
		status := "open"
		if p.Closed {
			status = "closed"
		}
		total := len(p.Yes) + len(p.No) + len(p.Abstain)
		sb.WriteString(ufmt.Sprintf("### Poll #%d [%s]\n", p.ID, status))
		sb.WriteString(ufmt.Sprintf("**Question:** %s\n\n", p.Question))
		sb.WriteString(ufmt.Sprintf("**Creator:** %s\n\n", p.Creator))
		sb.WriteString(ufmt.Sprintf("**Deadline (unix):** %s\n\n", strconv.FormatInt(p.Deadline, 10)))
		sb.WriteString(ufmt.Sprintf("| Yes | No | Abstain | Total |\n"))
		sb.WriteString("|-----|-----|---------|-------|\n")
		sb.WriteString(ufmt.Sprintf("| %d | %d | %d | %d |\n\n",
			len(p.Yes), len(p.No), len(p.Abstain), total))
	}
	return sb.String()
}